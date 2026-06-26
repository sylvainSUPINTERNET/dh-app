import 'package:flutter/foundation.dart';

const homeTabIndex = 0;
const notificationTabIndex = 1;
const quotesHistoryTabIndex = 2;

final selectedTabIndex = ValueNotifier<int>(homeTabIndex);

void openNotificationTab() {
  selectedTabIndex.value = notificationTabIndex;
}

void openQuotesHistoryTab() {
  selectedTabIndex.value = quotesHistoryTabIndex;
}
