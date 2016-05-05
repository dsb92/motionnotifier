//
//  IAP.swift
//  DeviceMotionNotifier
//
//  Created by David Buhauer on 06/04/2016.
//  Copyright © 2016 David Buhauer. All rights reserved.
//

import UIKit
import StoreKit

// Singleton
let sharedIAP = IAPManager()

protocol PurchaseProtocol {
    func errorPurchase(productId: String, errorMsg: String)
    func successPurchase(productId: String)
}

class IAPManager: NSObject {
    
    struct Products {
        let VideoCapture = "ncons.iap.videocapture"
        let SoundRegonition = "ncons.iap.soundrecognition"
        let RemoveAds = "ncons.iap.adsremoval"
    }
    
    // Save non-consumable in-app purchases
    let userDefaults = NSUserDefaults.standardUserDefaults()
    
    // Bool to determine whether IAP is enabled e.g. user is allowed to make payments.
    var canMakePayments : Bool = Bool()
    
    var purchaseProtocol : PurchaseProtocol?
    
    // Array of in-app purchases
    var list = [SKProduct]()
    
    // Stores one inn-app purchases
    var p = SKProduct()
    
    // The singleton
    class var sharedInstance : IAPManager {
        return sharedIAP
    }
    
    let products = Products()
    
    // e.g. restoring purchases...protocol may not be implemented, so we need the viewcontroller to show the dialog
    var vc: UIViewController?
    
    // Function to check whether user is allowed to make any payments.
    func startIAPCheck(){
        // Set IAPS
        if (SKPaymentQueue.canMakePayments()){
            print("In-AppPurchase: IAP is enabled..loading")
            let prodID: NSSet = NSSet(objects: products.VideoCapture, products.SoundRegonition, products.RemoveAds)
            let request: SKProductsRequest = SKProductsRequest(productIdentifiers: prodID as! Set<String>)
            request.delegate = self
            if (list.count == 0){
                request.start()
            }
            
            self.canMakePayments = true
        }
        else {
            print("In-AppPurchase: please enable IAPS")
            self.canMakePayments = false
        }
    }
    
    /* PUBLIC PURCHASE PRODUCT */
    func purchase(productToPurchase: String){
        for product in list {
            let prodID = product.productIdentifier
            if ( (prodID == products.VideoCapture && productToPurchase == products.VideoCapture) ||
                (prodID == products.SoundRegonition && productToPurchase == products.SoundRegonition) ||
                (prodID == products.RemoveAds && productToPurchase == products.RemoveAds) ){
                p = product
                buyProduct()
                break
            }
        }
    }
    
    /* PRIVATE IN-APP PURCHASE FUNCTIONS TO BE RUN */
    private func buyProduct() {
        print("In-AppPurchase: buy " + p.productIdentifier)
        
        let pay = SKPayment(product: p)
        SKPaymentQueue.defaultQueue().addTransactionObserver(self)
        SKPaymentQueue.defaultQueue().addPayment(pay as SKPayment)
    }
    
    // The buy transaction being processed
    private func buyTransaction(productID: String) {
        if purchaseProtocol == nil {
            print("Purchase protocol not implemented")
        }
        
        // If user wants to buy video capture
        if (productID == products.VideoCapture){
            print("In-AppPurchase: video capture")
            enableVideoCapture(productID)
        }
            // Else if user to buy sound recognition
        else if(productID == products.SoundRegonition){
            print("In-AppPurchase: sound recognition")
            enableSoundRecognition(productID)
        }
            
            // Else if user to buy sound recognition
        else if(productID == products.RemoveAds){
            print("In-AppPurchase: remove ads")
            removeAds(productID)
        }
            
        else{
            print("In-AppPurchase: IAP not setup")
        }
    }
    
    private func errorBuyingTransaction(productID: String, errorMsg: String){
        if (productID == products.VideoCapture){
            JSSAlertView().danger(self.vc!, title: "Error", text: "Could not restore video capture purchase")
        }

        else if(productID == products.SoundRegonition){
            JSSAlertView().danger(self.vc!, title: "Error", text: "Could not restore sound recognition purchase")
        }

        else if(productID == products.RemoveAds){
            JSSAlertView().danger(self.vc!, title: "Error", text: "Could not restore remove ads purchase")
        }
            
        else{
            print("In-AppPurchase: IAP not setup")
        }
        
        purchaseProtocol?.errorPurchase(productID, errorMsg: errorMsg)
    }
    
    func restorePurchases(){
        SKPaymentQueue.defaultQueue().addTransactionObserver(self)
        SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
    }
    
    /* PRODUCTS */
    
    private func enableVideoCapture(productID: String){
        print("In-AppPurchase: enabling video capture to your account!")
        userDefaults.setBool(true, forKey: "videocapture_enabled")
        JSSAlertView().success(self.vc!, title: "Success", text: "Video capturing is enabled!")
        purchaseProtocol?.successPurchase(productID)
    }
    
    private func enableSoundRecognition(productID: String){
        print("In-AppPurchase: enabling sound recognition to your account!")
        userDefaults.setBool(true, forKey: "soundrecognition_enabled")
        JSSAlertView().success(self.vc!, title: "Success", text: "Sound recognition is enabled!")
        purchaseProtocol?.successPurchase(productID)
    }
    
    private func removeAds(productID: String) {
        print("In-AppPurchase: enabling remove ads to your account!")
        userDefaults.setBool(true, forKey: "removeads_enabled")
        JSSAlertView().success(self.vc!, title: "Success", text: "Ads are removed!")
        purchaseProtocol?.successPurchase(productID)
    }
}

extension IAPManager : SKProductsRequestDelegate {
    func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        print("In-AppPurchase: product request")
        let myProduct = response.products
        
        for product in myProduct{
            print("In-AppPurchase: product added")
            print(product.productIdentifier)
            print(product.localizedTitle)
            print(product.localizedDescription)
            print(product.price)
            
            list.append(product )
        }
        
        // Sort the list price ascending order
        list.sortInPlace({$0.price.compare($1.price) == NSComparisonResult.OrderedAscending})
        
        print("In-AppPurchase: IAP is enabled..success")
    }
}

extension IAPManager : SKPaymentTransactionObserver {
    // Cancel or buy code to be run
    func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        print("In-AppPurchase: add payment")
        
        for transaction:AnyObject in transactions{
            let trans = transaction as! SKPaymentTransaction
            print(trans.error)
            
            switch trans.transactionState{
            case .Purchased:
                print("In-AppPurchase: buy, ok unlock iap here")
                print(p.productIdentifier)
                let prodID = p.productIdentifier as String
                buyTransaction(prodID)
                queue.finishTransaction(trans)
                break
            case .Failed:
                print("In-AppPurchase: buy error")
                JSSAlertView().danger(self.vc!, title: "Error", text: trans.error!.localizedDescription)
                purchaseProtocol?.errorPurchase(p.productIdentifier, errorMsg: trans.error!.localizedDescription)
                queue.finishTransaction(trans)
                break
                
            default:
                // Should not get here
                print("In-AppPurchase: default")
            }
        }
    }
    
    func finishTransaction(trans:SKPaymentTransaction){
        print("In-AppPurchase: finished trans")
    }
    
    func paymentQueue(queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        print("In-AppPurchase: removed trans")
        
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(queue: SKPaymentQueue) {
        print("In-AppPurchase: transactions restored")
        
        for transaction in queue.transactions {
            let t: SKPaymentTransaction = transaction
            
            let prodID = t.payment.productIdentifier as String
            
            buyTransaction(prodID)
            queue.finishTransaction(transaction)
        }
    }
    
    func paymentQueue(queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: NSError) {
        print("In-AppPurchase: transactions failed to restore")
        
        for transaction in queue.transactions {
            let t: SKPaymentTransaction = transaction
            
            let prodID = t.payment.productIdentifier as String
            
            errorBuyingTransaction(prodID, errorMsg: error.localizedDescription)
            queue.finishTransaction(transaction)
        }
    }
}
