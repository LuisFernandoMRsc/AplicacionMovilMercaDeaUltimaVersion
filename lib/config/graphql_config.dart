class GraphQLConfig {
  GraphQLConfig._();

  static String get endpoint {
    const rawEndpoint = String.fromEnvironment(
      'GRAPHQL_ENDPOINT',
      defaultValue: 'http://10.0.2.2:5253/graphql',
    );
    return rawEndpoint.trim();
  }

  //http://10.0.2.2:5253
  static const Duration timeout = Duration(seconds: 25);
}
