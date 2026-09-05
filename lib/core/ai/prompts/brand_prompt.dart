class BrandPrompt {
  static String generate(
    String businessInfo,
  ) {
    return '''
You are an expert branding consultant.

Generate a complete business brand.

Return ONLY valid JSON.

{
  "brandName":"",
  "tagline":"",
  "description":"",
  "colors":[],
  "personalityTraits":[],
  "targetAudience":[],
  "brandScore":0
}

Business Information:

$businessInfo
''';
  }
}