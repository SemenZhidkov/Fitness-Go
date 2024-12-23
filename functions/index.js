/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 * const {onRequest} = require("firebase-functions/v2/https");
 *   const logger = require("firebase-functions/logger");
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.cleanupOldTrainings = functions.firestore
    .document("Trainings/{trainingId}")
    .onCreate(async (snap, context) => {
      const now = admin.firestore.Timestamp.now();
      const fiveHours = new Date(now.toDate().getTime()- 5 * 60 * 60 * 1000);

      const trainingsRef = admin.firestore().collection("Trainings");
      const snapshot = await trainingsRef.where("date", "<", fiveHours).get();

      const batch = admin.firestore().batch();
      snapshot.forEach((doc) => {
        batch.delete(doc.ref);
      });

      await batch.commit();
      console.log("Deleted old trainings successfully");
    });
// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
