const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const twilio = require("twilio");

// Initialize Firebase
initializeApp();

// --- Load keys (This part is correct) ---
const accountSid = process.env.TWILIO_ACCOUNT_SID;
const authToken = process.env.TWILIO_AUTH_TOKEN;
const serviceSid = process.env.TWILIO_VERIFY_SERVICE_SID;

// --- Initialize Twilio Client (but check for keys first) ---
let twilioClient;
if (!accountSid) {
  console.error('Account SID missing');
}
if (!authToken) {
  console.error('Auth Token missing');
}
if (accountSid && authToken) {
  twilioClient = twilio(accountSid, authToken);
} else {
  console.error("Twilio Account SID or Auth Token is missing from .env!");
}

/**
 * [V2 Callable Function]
 * Sends a 6-digit verification code via SMS.
 */
exports.sendVerificationCode = onCall(async (request) => {
  // 1. Check for auth (Note: it's request.auth, not context.auth)
  if (!request.auth) {
    throw new HttpsError(
        "unauthenticated",
        "You must be logged in to verify your phone.",
    );
  }

  // 2. Check Twilio Client
  if (!twilioClient || !serviceSid) {
    throw new HttpsError("internal", "Twilio config is missing on server.");
  }
  
  const phoneNumber = request.data.phoneNumber;
  if (!phoneNumber) {
    throw new HttpsError(
        "invalid-argument",
        "The function must be called with a 'phoneNumber' argument.",
    );
  }

  try {
    const verification = await twilioClient.verify.v2
        .services(serviceSid)
        .verifications.create({to: phoneNumber, channel: "sms"});

    console.log(`Sent verification to ${phoneNumber}, status: ${verification.status}`);
    return {success: true, status: verification.status};
  } catch (error) {
    console.error(`Failed to send verification to ${phoneNumber}`, error);
    throw new HttpsError("internal", `Twilio Error: ${error.message}`);
  }
});

/**
 * [V2 Callable Function]
 * Takes a phone number and a 6-digit code to check if it's valid.
 */
exports.checkVerificationCode = onCall(async (request) => {
  // 1. Check for auth
  if (!request.auth) {
    throw new HttpsError(
        "unauthenticated",
        "You must be logged in to verify your phone.",
    );
  }

  // 2. Check Twilio Client
  if (!twilioClient || !serviceSid) {
    throw new HttpsError("internal", "Twilio config is missing on server.");
  }

  const phoneNumber = request.data.phoneNumber;
  const verificationCode = request.data.code;
  const userId = request.auth.uid; // Get the user's ID

  if (!phoneNumber || !verificationCode) {
    throw new HttpsError(
        "invalid-argument",
        "Missing 'phoneNumber' or 'code' arguments.",
    );
  }

  try {
    const verificationCheck = await twilioClient.verify.v2
        .services(serviceSid)
        .verificationChecks.create({to: phoneNumber, code: verificationCode});

    if (verificationCheck.status === "approved") {
      console.log(`Code approved for ${phoneNumber}. Updating Firestore.`);
      // Note: We get firestore with getFirestore() in V2
      const userDocRef = getFirestore().collection("users").doc(userId);
      
      await userDocRef.update({
        phone: phoneNumber,
        isPhoneVerified: true,
      });

      return {success: true, status: verificationCheck.status};
    } else {
      console.warn(
          `Code check failed for ${phoneNumber}, status: ${verificationCheck.status}`,
      );
      return {success: false, status: verificationCheck.status};
    }
  } catch (error) {
    console.error(`Failed to check verification for ${phoneNumber}`, error);
    throw new HttpsError("internal", `Twilio Error: ${error.message}`);
  }
});

/**
 * [V2 Callable Function]
 * Sends a hardcoded test SMS to the logged-in user's verified phone number.
 */
exports.testSms = onCall(async (request) => {
  // 1. Check for auth
  if (!request.auth) {
    throw new HttpsError(
        "unauthenticated",
        "You must be logged in to test SMS.",
    );
  }

  // 2. Check Twilio Client
  if (!twilioClient || !serviceSid) {
    throw new HttpsError("internal", "Twilio config is missing on server.");
  }
  
  const userId = request.auth.uid;

  try {
    const userDocRef = getFirestore().collection("users").doc(userId);
    const userDoc = await userDocRef.get();

    if (!userDoc.exists) {
      throw new HttpsError("not-found", "User profile not found.");
    }

    const userData = userDoc.data();
    const phoneNumber = userData.phone;
    const isVerified = userData.isPhoneVerified;

    if (!isVerified || !phoneNumber) {
      throw new HttpsError(
          "failed-precondition",
          "Your phone number is not verified. Please verify it first.",
      );
    }

    // 4. Send the Test SMS
    
    await twilioClient.messages.create({
      body: "This is a test message from your Random Reminder app!",
      from: "+18776575691", // IMPORTANT: Remember to use your Twilio #
      to: phoneNumber,
    });

    console.log(`Test SMS sent successfully to ${phoneNumber}`);
    return {success: true, message: "Test SMS sent!"};
  } catch (error) {
    console.error(`Failed to send test SMS to user ${userId}`, error);
    if (error instanceof HttpsError) {
      throw error; // Re-throw our own errors
    }
    throw new HttpsError(
        "internal",
        `Failed to send test SMS: ${error.message}`,
    );
  }
});