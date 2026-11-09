// Stand-in for firebase-admin in tests: no network, deterministic tokens.
const users = new Map();

module.exports = {
  initializeApp() {},
  credential: { cert: () => ({}) },
  auth: () => ({
    async getUserByPhoneNumber(phone) {
      const user = users.get(phone);
      if (!user) throw Object.assign(new Error('not found'), { code: 'auth/user-not-found' });
      return user;
    },
    async createUser({ uid, phoneNumber }) {
      const user = { uid, phoneNumber };
      users.set(phoneNumber, user);
      return user;
    },
    async createCustomToken(uid) {
      return `fake-token-for-${uid}`;
    },
  }),
};
