const {onCall, HttpsError} = require("firebase-functions/v2/https");

// Stripe secret key from environment variable
// Set this in Firebase Console: Functions > Configuration
const STRIPE_SECRET_KEY = process.env.STRIPE_SECRET_KEY;

/**
 * Cloud Function to create a Stripe PaymentIntent
 * This function should be called from the Flutter app
 */
exports.createPaymentIntent = onCall(
    {
      cors: true,
    },
    async (request) => {
      // Verify authentication
      if (!request.auth) {
        throw new HttpsError(
            "unauthenticated",
            "User must be authenticated to create payment intent",
        );
      }

      // Extract parameters
      const {amount, currency = "jpy", metadata = {}} = request.data;

      // Validate amount
      if (!amount || typeof amount !== "number" || amount <= 0) {
        throw new HttpsError(
            "invalid-argument",
            "Amount must be a positive number",
        );
      }

      try {
        // Initialize Stripe with secret key from environment
        const stripe = require("stripe")(STRIPE_SECRET_KEY);

        // Create PaymentIntent
        const paymentIntent = await stripe.paymentIntents.create({
          amount: amount,
          currency: currency,
          automatic_payment_methods: {
            enabled: true,
          },
          metadata: {
            ...metadata,
            userId: request.auth.uid,
            userEmail: request.auth.token.email || "unknown",
          },
        });

        // Return client secret to Flutter app
        return {
          clientSecret: paymentIntent.client_secret,
          paymentIntentId: paymentIntent.id,
        };
      } catch (error) {
        console.error("Error creating payment intent:", error);
        throw new HttpsError(
            "internal",
            "Failed to create payment intent: " + error.message,
        );
      }
    },
);

/**
 * Cloud Function to verify payment status
 * Call this after payment completion to verify the payment was successful
 */
exports.verifyPayment = onCall(
    {
      cors: true,
    },
    async (request) => {
      if (!request.auth) {
        throw new HttpsError(
            "unauthenticated",
            "User must be authenticated",
        );
      }

      const {paymentIntentId} = request.data;

      if (!paymentIntentId) {
        throw new HttpsError(
            "invalid-argument",
            "Payment Intent ID is required",
        );
      }

      try {
        const stripe = require("stripe")(STRIPE_SECRET_KEY);
        const paymentIntent = await stripe.paymentIntents.retrieve(
            paymentIntentId,
        );

        return {
          status: paymentIntent.status,
          amount: paymentIntent.amount,
          currency: paymentIntent.currency,
          metadata: paymentIntent.metadata,
        };
      } catch (error) {
        console.error("Error verifying payment:", error);
        throw new HttpsError(
            "internal",
            "Failed to verify payment: " + error.message,
        );
      }
    },
);
