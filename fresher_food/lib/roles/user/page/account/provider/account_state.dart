class AccountState {
  final Map<String, dynamic>? userInfo;
  final bool isLoading;
  final bool isLoggedIn;
  final int orderCount;
  final int favoriteCount;

  const AccountState({
    this.userInfo,
    this.isLoading = true,
    this.isLoggedIn = false,
    this.orderCount = 0,
    this.favoriteCount = 0,
  });

  AccountState copyWith({
    Map<String, dynamic>? userInfo,
    bool? isLoading,
    bool? isLoggedIn,
    int? orderCount,
    int? favoriteCount,
  }) {
    return AccountState(
      userInfo: userInfo ?? this.userInfo,
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      orderCount: orderCount ?? this.orderCount,
      favoriteCount: favoriteCount ?? this.favoriteCount,
    );
  }
}