//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterConfigDataHelpPath+PurchaseInformation.swift
//
//  Created by Facundo Menzella on 4/5/25.

import Foundation
import RevenueCat

extension CustomerCenterConfigData.HelpPath {
    func isEligibleForPurchase(
        _ purchaseInformation: PurchaseInformation?
    ) -> CustomerCenterConfigData.HelpPath? {
        guard let purchaseInformation else {
            return self
        }

        // if it's cancel, it cannot be a lifetime subscription
        let isCancel = type == .cancel
        let isEligibleCancel = !purchaseInformation.isLifetime && !purchaseInformation.isCancelled

        // if it's refundRequest, it cannot be free  nor within trial period
        let isRefund = type == .refundRequest
        let isRefundEligible = purchaseInformation.price != .free
                                && !purchaseInformation.isTrial
                                && !purchaseInformation.isCancelled

        // if it has a refundDuration, check it's still valid
        let refundWindowIsValid = refundWindowDuration?.isWithin(purchaseInformation) ?? true

        return ((!isCancel || isEligibleCancel) &&
                (!isRefund || isRefundEligible) &&
                refundWindowIsValid) ? self : nil
    }
}

private extension CustomerCenterConfigData.HelpPath.RefundWindowDuration {
    func isWithin(_ purchaseInformation: PurchaseInformation) -> Bool {
        switch self {
        case .forever:
            return true

        case let .duration(duration):
            return duration.isWithin(
                from: purchaseInformation.latestPurchaseDate,
                now: purchaseInformation.customerInfoRequestedDate
            )

        @unknown default:
            return true
        }
    }
}

private extension ISODuration {
    func isWithin(from startDate: Date?, now: Date) -> Bool {
        guard let startDate else {
            return true
        }

        var dateComponents = DateComponents()
        dateComponents.year = self.years
        dateComponents.month = self.months
        dateComponents.weekOfYear = self.weeks
        dateComponents.day = self.days
        dateComponents.hour = self.hours
        dateComponents.minute = self.minutes
        dateComponents.second = self.seconds

        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: dateComponents, to: startDate) ?? startDate

        return startDate < endDate && now <= endDate
    }
}
