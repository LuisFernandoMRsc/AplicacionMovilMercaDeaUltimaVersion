import 'dart:io';

import 'package:graphql_flutter/graphql_flutter.dart';

import '../config/graphql_config.dart';
import 'token_storage.dart';

class GraphQLFailure implements Exception {
  GraphQLFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class GraphQLService {
  GraphQLService({TokenStorage? tokenStorage})
      : _tokenStorage = tokenStorage ?? TokenStorage();

  final TokenStorage _tokenStorage;

  Future<QueryResult> query({
    required String document,
    Map<String, dynamic>? variables,
    bool requiresAuth = true,
  }) async {
    final client = await _client(requiresAuth: requiresAuth);
    final options = QueryOptions(
      document: gql(document),
      variables: variables ?? const <String, dynamic>{},
      fetchPolicy: FetchPolicy.networkOnly,
    );

    final result = await client.query(options);
    _throwOnError(result);
    return result;
  }

  Future<QueryResult> mutate({
    required String document,
    Map<String, dynamic>? variables,
    bool requiresAuth = true,
  }) async {
    final client = await _client(requiresAuth: requiresAuth);
    final options = MutationOptions(
      document: gql(document),
      variables: variables ?? const <String, dynamic>{},
      fetchPolicy: FetchPolicy.noCache,
    );

    final result = await client.mutate(options);
    _throwOnError(result);
    return result;
  }

  Future<GraphQLClient> _client({required bool requiresAuth}) async {
    final httpLink = HttpLink(
      GraphQLConfig.endpoint,
      defaultHeaders: const {
        'Content-Type': 'application/json',
      },
    );

    Link link = httpLink;
    if (requiresAuth) {
      final token = await _tokenStorage.readToken();
      if (token == null || token.isEmpty) {
        throw GraphQLFailure('Debes iniciar sesión para continuar.');
      }
      final authLink = AuthLink(getToken: () async => 'Bearer $token');
      link = authLink.concat(httpLink);
    }

    return GraphQLClient(
      cache: GraphQLCache(store: InMemoryStore()),
      link: link,
    );
  }

  void _throwOnError(QueryResult result) {
    if (!result.hasException) return;
    final exception = result.exception;
    if (exception == null) {
      throw GraphQLFailure('Error desconocido de GraphQL.');
    }

    final linkException = exception.linkException;
    if (_isConnectivityIssue(linkException)) {
      throw GraphQLFailure('No tienes conexión a internet.');
    }

    if (exception.graphqlErrors.isNotEmpty) {
      final messages = exception.graphqlErrors
          .map((error) => _extractGraphQLErrorMessage(error))
          .where((m) => m != null && m!.trim().isNotEmpty)
          .map((m) => m!.trim())
          .toList();

      if (messages.isNotEmpty) {
        throw GraphQLFailure(messages.join('. '));
      }
    }

    final linkMessage = linkException?.originalException?.toString() ??
        linkException?.toString() ??
        'No fue posible comunicarse con el servidor.';
    throw GraphQLFailure(linkMessage);
  }

  bool _isConnectivityIssue(LinkException? linkException) {
    if (linkException == null) return false;
    final original = linkException.originalException;
    if (original is SocketException ||
        original is HandshakeException ||
        original is TlsException) {
      return true;
    }

    final description = original?.toString() ?? linkException.toString();
    return description.toLowerCase().contains('failed host lookup') ||
        description.toLowerCase().contains('no address associated with hostname') ||
        description.toLowerCase().contains('network is unreachable');
  }

  String? _extractGraphQLErrorMessage(GraphQLError error) {
    final extensionMessage = _extractExtensionMessage(error.extensions);
    if (extensionMessage != null && extensionMessage.trim().isNotEmpty) {
      return extensionMessage;
    }
    return error.message;
  }

  String? _extractExtensionMessage(Map<String, dynamic>? extensions) {
    if (extensions == null) return null;

    final possibleKeys = ['message', 'messages', 'detail', 'details'];
    for (final key in possibleKeys) {
      final value = extensions[key];
      if (value == null) continue;

      if (value is String && value.trim().isNotEmpty) {
        return value;
      }

      if (value is Iterable) {
        final joined = value
            .whereType<String>()
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .join('. ');
        if (joined.isNotEmpty) {
          return joined;
        }
      }
    }

    return null;
  }
}
