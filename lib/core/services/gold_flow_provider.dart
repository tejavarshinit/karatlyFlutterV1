import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gold_flow_model.dart';

// ── Gold Flow Notifier ──
class GoldFlowNotifier extends StateNotifier<GoldFlowState> {
  GoldFlowNotifier() : super(const GoldFlowState());

  void setBuyState(BuyState buyState) {
    state = state.copyWith(buyState: buyState);
  }

  void updateBuyState({
    String? type,
    String? sku,
    double? amount,
    double? rate,
    String? blockId,
    String? uniqueId,
    double? grams,
    double? preTax,
    double? gst,
    double? totalPaid,
    String? brand,
    String? address,
    String? paymentMethod,
    String? transactionId,
    String? merchantTransactionId,
    String? paymentStatus,
    String? paymentMessage,
    String? metalType,
    String? addressId,
    bool? isRedeemPayment,
    String? couponCode,
    String? reservationId,
    double? couponDiscount,
    bool? couponApplied,
    String? employeeId,
    String? corporateId,
    String? couponReservationId,
  }) {
    state = state.copyWith(
      buyState: state.buyState.copyWith(
        type: type,
        sku: sku,
        amount: amount,
        rate: rate,
        blockId: blockId,
        uniqueId: uniqueId,
        grams: grams,
        preTax: preTax,
        gst: gst,
        totalPaid: totalPaid,
        brand: brand,
        address: address,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
        merchantTransactionId: merchantTransactionId,
        paymentStatus: paymentStatus,
        paymentMessage: paymentMessage,
        metalType: metalType,
        addressId: addressId,
        isRedeemPayment: isRedeemPayment,
        couponCode: couponCode,
        reservationId: reservationId,
        couponDiscount: couponDiscount,
        couponApplied: couponApplied,
        employeeId: employeeId,
        corporateId: corporateId,
        couponReservationId: couponReservationId,
      ),
    );
  }

  void setSellState(SellState sellState) {
    state = state.copyWith(sellState: sellState);
  }

  void updateSellState({
    double? amount,
    double? rate,
    String? blockId,
    String? uniqueId,
    double? grams,
    double? payout,
    double? platformFee,
    String? userBankId,
    String? bankName,
    String? transactionId,
    String? merchantTransactionId,
    String? orderStatus,
    String? metalType,
  }) {
    state = state.copyWith(
      sellState: state.sellState.copyWith(
        amount: amount,
        rate: rate,
        blockId: blockId,
        uniqueId: uniqueId,
        grams: grams,
        payout: payout,
        platformFee: platformFee,
        userBankId: userBankId,
        bankName: bankName,
        transactionId: transactionId,
        merchantTransactionId: merchantTransactionId,
        orderStatus: orderStatus,
        metalType: metalType,
      ),
    );
  }

  void setSipState(SipState sipState) {
    state = state.copyWith(sipState: sipState);
  }

  void updateSipState({
    double? amount,
    double? rate,
    String? blockId,
    String? uniqueId,
    String? metalType,
    String? frequency,
    int? date,
    int? cycles,
    String? type,
    String? brand,
    String? transactionId,
    String? merchantTransactionId,
  }) {
    state = state.copyWith(
      sipState: state.sipState.copyWith(
        amount: amount,
        rate: rate,
        blockId: blockId,
        uniqueId: uniqueId,
        metalType: metalType,
        frequency: frequency,
        date: date,
        cycles: cycles,
        type: type,
        brand: brand,
        transactionId: transactionId,
        merchantTransactionId: merchantTransactionId,
      ),
    );
  }

  void clearAll() {
    state = const GoldFlowState();
  }
}

// ── Provider ──
final goldFlowProvider = StateNotifierProvider<GoldFlowNotifier, GoldFlowState>((ref) {
  return GoldFlowNotifier();
});
