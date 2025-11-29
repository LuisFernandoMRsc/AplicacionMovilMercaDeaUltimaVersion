class GraphQLConfig {
  GraphQLConfig._();

  static const String endpoint = String.fromEnvironment(
    'GRAPHQL_ENDPOINT',
    defaultValue: 'http://10.0.2.2:5253/graphql',
  );

  static const Duration timeout = Duration(seconds: 25);
}
