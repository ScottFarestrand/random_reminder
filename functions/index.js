const functions = require("firebase-functions");
const admin = require("firebase-admin");
const twilio = require("twilio");

admin.initializeApp();

// --- NOTE: ALL GLOBAL VARIABLES ARE GONE ---
// We will load them "just-in-time" inside the functions.

/**
 * [Callable Function]
 * Takes a phone number and sends a 6-digit verification code via SMS.
 */
exports.sendVerificationCode = functions.https.onCall(async (data, context) => {
  // --- LOAD KEYS *INSIDE* THE FUNCTION ---
  const accountSid = process.env.TWILIO_ACCOUNT_SID;
  const authToken = process.env.TWILIO_AUTH_TOKEN;
  const serviceSid = process.env.TWILIO_VERIFY_SERVICE_SID;

  if (!accountSid || !authToken || !serviceSid) {
    console.error("Twilio config is missing. Check .env file and deployment.");
    throw new functions.https.HttpsError("internal", "Twilio config is missing.");
  }
  const twilioClient = twilio(accountSid, authToken);
  // --- END NEW LOGIC ---

  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be logged in to verify your phone.",
    );
  }

  const phoneNumber = data.phoneNumber;
  if (!phoneNumber) {
    throw new functions.https.HttpsError(
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
    throw new functions.https.HttpsError(
        "internal",
        `Twilio Error: ${error.message}`,
    );
  }
});

/**
 * [Callable Function]
 * Takes a phone number and a 6-digit code to check if it's valid.
 */
exports.checkVerificationCode = functions.https.onCall(async (data, context) => {
  // --- LOAD KEYS *INSIDE* THE FUNCTION ---
  const accountSid = process.env.TWILIO_ACCOUNT_SID;
  const authToken = process.env.TWILIO_AUTH_TOKEN;
  const serviceSid = process.env.TWILIO_VERIFY_SERVICE_SID;

  if (!accountSid || !authToken || !serviceSid) {
    console.error("Twilio config is missing. Check .env file and deployment.");
    throw new functions.https.HttpsError("internal", "Twilio config is missing.");
  }
  const twilioClient = twilio(accountSid, authToken);
  // --- END NEW LOGIC ---

  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "You must be logged in to verify your phone.",
    );
  }

  const phoneNumber = data.phoneNumber;
  const verificationCode = data.code;
  const userId = context.auth.uid;

  if (!phoneNumber || !verificationCode) {
    throw new functions.https.HttpsError(
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
      const userDocRef = admin.firestore().collection("users").doc(userId);
      
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
    throw new functions.https.HttpsError(
        "internal",
        `Twilio Error: ${error.message}`,
    );
  }
});