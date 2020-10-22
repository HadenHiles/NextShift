class SubscriptionResponse {
  final List<dynamic> subscriptions;
  final String error;

  SubscriptionResponse({this.subscriptions, this.error});

  factory SubscriptionResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionResponse(
      subscriptions: json['subscriptions'],
      error: json['error'],
    );
  }
}
