class SubscriptionResponse {
  final List<dynamic> subscriptions;
  final String? error;

  SubscriptionResponse({required this.subscriptions, this.error});

  factory SubscriptionResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionResponse(
      subscriptions: json['subscriptions'] as List<dynamic>? ?? [],
      error: json['error'] as String?,
    );
  }
}
