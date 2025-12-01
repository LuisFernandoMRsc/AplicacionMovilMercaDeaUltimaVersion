class GraphQLConfig {
  GraphQLConfig._();

  static const String endpoint = String.fromEnvironment(
    'GRAPHQL_ENDPOINT',
    defaultValue: 'https://e595ce7f8cd7.ngrok-free.app/graphql',
  );

  //http://10.0.2.2:5253
  static const Duration timeout = Duration(seconds: 25);
}
