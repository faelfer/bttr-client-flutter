enum Environment {
  dev,
  qa,
  prod;

  static Environment parse(String value) => switch (value.toLowerCase()) {
    'dev' || 'development' => dev,
    'qa' || 'staging' || 'homolog' => qa,
    _ => prod,
  };

  String get asset => switch (this) {
    dev => 'env/.env.dev',
    qa => 'env/.env.qa',
    prod => 'env/.env',
  };
}
