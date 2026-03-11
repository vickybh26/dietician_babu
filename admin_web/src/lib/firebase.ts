import { initializeApp, getApps, getApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";
import { getAuth } from "firebase/auth";

const firebaseConfig = {
  apiKey: "AIzaSyBqbtLbgmrLdAX07k1tveU_3kqysceqBtY",
  authDomain: "dietician-babu-31ka2.firebaseapp.com",
  projectId: "dietician-babu-31ka2",
  storageBucket: "dietician-babu-31ka2.firebasestorage.app",
  messagingSenderId: "793278867167",
  appId: "1:793278867167:web:a2f5f6808ea2e8b7392b6a",
};

const app = !getApps().length ? initializeApp(firebaseConfig) : getApp();
const db = getFirestore(app, "dieticianbabu");
const auth = getAuth(app);

export { app, db, auth };
