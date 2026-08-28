(() => {
  const TOKEN_KEY = 'tourismAuthToken';
  const USER_KEY = 'tourismAuthUser';
  const SIGNUP_STATE_KEY = 'tourismSignupState';
  const API_BASE_URL = window.APP_API_BASE_URL || (window.location.port === '3000' ? '' : 'http://127.0.0.1:3000');
  const state = {
    mode: 'login',
    signupStep: 'details',
    pendingEmail: '',
    pendingName: '',
    codeExpiresAt: 0,
    resendAvailableAt: 0,
  };

  const els = {};
  let resendTimerId = null;

  function byId(id) {
    return document.getElementById(id);
  }

  function readStoredUser() {
    try {
      return JSON.parse(localStorage.getItem(USER_KEY) || 'null');
    } catch {
      return null;
    }
  }

  function readStoredToken() {
    return localStorage.getItem(TOKEN_KEY) || '';
  }

  function readSignupState() {
    try {
      return JSON.parse(sessionStorage.getItem(SIGNUP_STATE_KEY) || 'null');
    } catch {
      return null;
    }
  }

  function saveSignupState() {
    try {
      sessionStorage.setItem(SIGNUP_STATE_KEY, JSON.stringify({
        mode: state.mode,
        signupStep: state.signupStep,
        pendingEmail: state.pendingEmail,
        pendingName: state.pendingName,
        codeExpiresAt: state.codeExpiresAt,
        resendAvailableAt: state.resendAvailableAt,
      }));
    } catch {
      // ignore
    }
  }

  function clearSignupState() {
    try {
      sessionStorage.removeItem(SIGNUP_STATE_KEY);
    } catch {
      // ignore
    }
  }

  function clearResendTimer() {
    if (resendTimerId) {
      clearInterval(resendTimerId);
      resendTimerId = null;
    }
  }

  function formatCountdown(seconds) {
    const totalSeconds = Math.max(0, Math.ceil(seconds));
    const minutes = Math.floor(totalSeconds / 60);
    const remainingSeconds = totalSeconds % 60;
    if (minutes <= 0) {
      return `${remainingSeconds}s`;
    }
    return `${minutes}m ${String(remainingSeconds).padStart(2, '0')}s`;
  }

  function updateResendButton() {
    if (!els.resendCodeBtn) return;

    if (state.signupStep !== 'code') {
      els.resendCodeBtn.disabled = true;
      els.resendCodeBtn.textContent = 'Resend';
      return;
    }

    const waitMs = Math.max(0, (state.resendAvailableAt || 0) - Date.now());
    if (waitMs > 0) {
      els.resendCodeBtn.disabled = true;
      els.resendCodeBtn.textContent = `Resend in ${formatCountdown(waitMs / 1000)}`;
      return;
    }

    els.resendCodeBtn.disabled = false;
    els.resendCodeBtn.textContent = 'Resend';
  }

  function startResendTimer() {
    clearResendTimer();
    updateResendButton();
    resendTimerId = window.setInterval(updateResendButton, 1000);
  }

  function applySignupMeta(data, email, name) {
    state.pendingEmail = data?.email || email || state.pendingEmail || '';
    state.pendingName = data?.name || name || state.pendingName || '';
    state.codeExpiresAt = data?.codeExpiresAt || 0;
    state.resendAvailableAt = data?.resendAvailableAt || 0;
    saveSignupState();
  }

  function saveSession(token, user) {
    localStorage.setItem(TOKEN_KEY, token);
    localStorage.setItem(USER_KEY, JSON.stringify(user));
    try {
      window.dispatchEvent(new CustomEvent('tourism:auth-changed', { detail: { user } }));
    } catch (e) {
      // ignore
    }
  }

  function clearSession() {
    localStorage.removeItem(TOKEN_KEY);
    localStorage.removeItem(USER_KEY);
    try {
      window.dispatchEvent(new CustomEvent('tourism:auth-changed', { detail: { user: null } }));
    } catch (e) {
      // ignore
    }
  }

  async function request(path, options = {}) {
    const headers = Object.assign({ 'Content-Type': 'application/json' }, options.headers || {});
    const token = readStoredToken();
    if (token && !headers.Authorization) {
      headers.Authorization = `Bearer ${token}`;
    }

    const response = await fetch(`${API_BASE_URL}${path}`, Object.assign({}, options, { headers }));
    const payload = await response.json().catch(() => ({}));

    if (!response.ok) {
      throw new Error(payload.error || payload.message || `Request failed (${response.status})`);
    }

    return payload;
  }

  function showMessage(text, tone = 'info') {
    if (!els.authMessage) return;
    els.authMessage.textContent = text || '';
    els.authMessage.dataset.tone = tone;
  }

  function setModalOpen(isOpen) {
    if (!els.authModal) return;
    els.authModal.classList.toggle('is-open', isOpen);
    els.authModal.setAttribute('aria-hidden', isOpen ? 'false' : 'true');
    document.body.style.overflow = isOpen ? 'hidden' : '';
    try {
      document.body.classList.toggle('auth-active', isOpen);
    } catch (e) {
      // ignore
    }
  }

  function setMode(mode) {
    state.mode = mode;
    state.signupStep = mode === 'signup' ? state.signupStep : 'details';
    showMessage('');

    if (els.loginForm) els.loginForm.classList.toggle('hidden', mode !== 'login');
    if (els.signupForm) els.signupForm.classList.toggle('hidden', mode !== 'signup');

    document.querySelectorAll('[data-auth-mode]').forEach((button) => {
      button.classList.toggle('active', button.dataset.authMode === mode);
    });

    renderSignupStep();
    saveSignupState();
  }

  function renderSignupStep(step = state.signupStep) {
    state.signupStep = step;
    const mapping = {
      details: ['details'],
      code: ['code'],
      password: ['password'],
    };

    document.querySelectorAll('[data-step]').forEach((panel) => {
      const current = panel.dataset.step;
      const visible = (mapping[step] || []).includes(current);
      panel.classList.toggle('hidden', !visible);
    });

    if (step === 'code') {
      startResendTimer();
    } else {
      clearResendTimer();
      updateResendButton();
    }

    saveSignupState();
  }

  function updateHeaderState(user) {
    const authButton = els.authOpenBtn;
    const accountButton = els.accountButton;
    const logoutBtn = els.logoutBtn;

    if (user) {
      const firstName = (user.name || 'Account').trim().split(/\s+/)[0] || 'Account';
      if (authButton) authButton.hidden = true;
      if (accountButton) {
        accountButton.hidden = false;
        if (user.role === 'admin') {
          accountButton.textContent = 'Admin Dashboard';
          accountButton.classList.add('admin-pill');
        } else {
          accountButton.textContent = `Hi, ${firstName}`;
          accountButton.classList.remove('admin-pill');
        }

        accountButton.title = user.email || 'Signed in';
        accountButton.dataset.loggedIn = 'true';
        accountButton.onclick = () => {
          if (user.role === 'admin') window.location.href = '/admin-dashboard';
          else window.location.href = '/user-dashboard';
        };

      }
      if (logoutBtn) logoutBtn.hidden = false;
      return;
    }


    if (authButton) authButton.hidden = false;
    if (accountButton) {
      accountButton.hidden = true;
      accountButton.dataset.loggedIn = 'false';
    }
    if (logoutBtn) logoutBtn.hidden = true;
  }

  async function validateSession() {
    const token = readStoredToken();
    if (!token) {
      updateHeaderState(null);
      return;
    }

    try {
      const data = await request('/api/auth/me', {
        method: 'GET',
        headers: { Authorization: `Bearer ${token}` },
      });
      if (data?.user) {
        saveSession(token, data.user);
        updateHeaderState(data.user);
        return;
      }
    } catch {
      clearSession();
    }

    updateHeaderState(null);
  }

  function openModal(mode = 'login') {
    setModalOpen(true);
    setMode(mode);
    if (mode === 'signup') {
      renderSignupStep(state.signupStep || 'details');
    }

    if (mode === 'login' && els.loginEmail) {
      els.loginEmail.focus();
    }

    if (mode === 'signup' && els.signupName) {
      els.signupName.focus();
    }
  }

  function closeModal() {
    setModalOpen(false);
    showMessage('');
  }

  async function startSignup() {
    const isDetailsStep = state.signupStep === 'details' || !state.signupStep;
    const name = (isDetailsStep ? els.signupName?.value : state.pendingName || els.signupName?.value || '').trim();
    const email = (isDetailsStep ? els.signupEmail?.value : state.pendingEmail || els.signupEmail?.value || '').trim();

    if (!name) {
      showMessage('Please enter your full name.', 'error');
      els.signupName?.focus();
      return;
    }

    if (!email || !email.includes('@')) {
      showMessage('Please enter a valid email address.', 'error');
      els.signupEmail?.focus();
      return;
    }

    showMessage('Sending verification code...', 'info');

    try {
      const data = await request('/api/auth/signup/start', {
        method: 'POST',
        body: JSON.stringify({ name, email }),
      });

      applySignupMeta(data, email, name);
      if (data.nextStep === 'set-password') {
        renderSignupStep('password');
        showMessage('Your email is already verified. Set your password to finish account creation.', 'success');
        els.signupPassword?.focus();
        return;
      }

      renderSignupStep('code');
      showMessage(
        data.delivery === 'mock'
          ? `[MOCK] Verification code for ${email} is: ${data.previewCode}`
          : `Verification code sent to ${email}. Enter the code to continue.`,
        'success'
      );
      els.verificationCode?.focus();
      if (data.delivery === 'mock' && els.verificationCode) {
        els.verificationCode.value = data.previewCode;
      }
    } catch (err) {
      showMessage(err.message || 'Could not send verification code.', 'error');
    }
  }

  async function resendCode() {
    const email = state.pendingEmail || (els.signupEmail?.value || '').trim();

    if (!email) {
      showMessage('Start the signup process again.', 'error');
      renderSignupStep('details');
      return;
    }

    showMessage('Resending verification code...', 'info');

    try {
      const data = await request('/api/auth/signup/resend', {
        method: 'POST',
        body: JSON.stringify({ email }),
      });

      applySignupMeta(data, email, state.pendingName);
      renderSignupStep('code');
      showMessage(
        data.delivery === 'mock'
          ? `[MOCK] New verification code for ${email} is: ${data.previewCode}`
          : `A new verification code was sent to ${email}.`,
        'success'
      );
      if (data.delivery === 'mock' && els.verificationCode) {
        els.verificationCode.value = data.previewCode;
      }
      els.verificationCode?.focus();
    } catch (err) {
      showMessage(err.message || 'Could not resend verification code.', 'error');
    }
  }

  async function verifyCode() {
    const email = state.pendingEmail || (els.signupEmail?.value || '').trim();
    const code = (els.verificationCode?.value || '').trim();

    if (!email) {
      showMessage('Start the signup process again.', 'error');
      renderSignupStep('details');
      return;
    }

    if (!code) {
      showMessage('Please enter the verification code.', 'error');
      els.verificationCode?.focus();
      return;
    }

    showMessage('Checking verification code...', 'info');

    try {
      await request('/api/auth/signup/verify-code', {
        method: 'POST',
        body: JSON.stringify({ email, code }),
      });

      renderSignupStep('password');
      showMessage('Code verified. Now create your password.', 'success');
      els.signupPassword?.focus();
      saveSignupState();
    } catch (err) {
      showMessage(err.message || 'Invalid verification code.', 'error');
    }
  }

  async function setPassword() {
    const email = state.pendingEmail || (els.signupEmail?.value || '').trim();
    const password = els.signupPassword?.value || '';
    const confirmPassword = els.signupPasswordConfirm?.value || '';

    if (!email) {
      showMessage('Please restart signup and verify your email again.', 'error');
      renderSignupStep('details');
      return;
    }

    if (password.length < 6) {
      showMessage('Password must be at least 6 characters.', 'error');
      els.signupPassword?.focus();
      return;
    }

    if (password !== confirmPassword) {
      showMessage('Passwords do not match.', 'error');
      els.signupPasswordConfirm?.focus();
      return;
    }

    showMessage('Creating your account...', 'info');

    try {
      const data = await request('/api/auth/signup/set-password', {
        method: 'POST',
        body: JSON.stringify({ email, password, confirmPassword, name: state.pendingName }),
      });

      saveSession(data.token, data.user);
      updateHeaderState(data.user);
      closeModal();
      showMessage(`Welcome, ${data.user.name}. Your account is ready.`, 'success');
      resetSignupFlow();
      clearSignupState();
    } catch (err) {
      showMessage(err.message || 'Could not create account.', 'error');
    }
  }

  async function login() {
    const email = (els.loginEmail?.value || '').trim();
    const password = els.loginPassword?.value || '';

    if (!email || !email.includes('@')) {
      showMessage('Please enter a valid email address.', 'error');
      els.loginEmail?.focus();
      return;
    }

    if (!password) {
      showMessage('Please enter your password.', 'error');
      els.loginPassword?.focus();
      return;
    }

    showMessage('Logging you in...', 'info');

    try {
      const data = await request('/api/auth/login', {
        method: 'POST',
        body: JSON.stringify({ email, password }),
      });

      saveSession(data.token, data.user);
      updateHeaderState(data.user);
      closeModal();
      showMessage(`Welcome back, ${data.user.name}.`, 'success');
      
      setTimeout(() => {
        if (data.user.role === 'admin') {
          window.location.href = '/admin-dashboard';
        } else {
          window.location.href = '/user-dashboard';
        }
      }, 1000);


    } catch (err) {
      const msg = err.message || 'Login failed.';
      showMessage(msg, 'error');
    }
  }

  async function logout() {
    const token = readStoredToken();
    try {
      if (token) {
        await request('/api/auth/logout', {
          method: 'POST',
          headers: { Authorization: `Bearer ${token}` },
        });
      }
    } catch {
      // Ignore logout errors and clear local state anyway.
    }

    clearSession();
    updateHeaderState(null);
    openModal('login');
    showMessage('You have been signed out.', 'info');
  }

  function resetSignupFlow() {
    state.pendingEmail = '';
    state.pendingName = '';
    state.signupStep = 'details';
    state.codeExpiresAt = 0;
    state.resendAvailableAt = 0;
    clearResendTimer();

    if (els.signupName) els.signupName.value = '';
    if (els.signupEmail) els.signupEmail.value = '';
    if (els.verificationCode) els.verificationCode.value = '';
    if (els.signupPassword) els.signupPassword.value = '';
    if (els.signupPasswordConfirm) els.signupPasswordConfirm.value = '';

    renderSignupStep('details');
    clearSignupState();
  }

  function bindEvents() {
    els.authOpenBtn?.addEventListener('click', () => openModal('login'));


    els.logoutBtn?.addEventListener('click', () => {
      const shouldLogout = window.confirm('Sign out of your account?');
      if (shouldLogout) logout();
    });

    document.querySelectorAll('[data-auth-close]').forEach((item) => {
      item.addEventListener('click', closeModal);
    });

    document.querySelectorAll('[data-auth-mode]').forEach((button) => {
      button.addEventListener('click', () => {
        const mode = button.dataset.authMode || 'login';
        setMode(mode);
      });
    });

    els.loginForm?.addEventListener('submit', (event) => {
      event.preventDefault();
      login();
    });

    els.sendCodeBtn?.addEventListener('click', (event) => {
      event.preventDefault();
      startSignup();
    });

    els.resendCodeBtn?.addEventListener('click', (event) => {
      event.preventDefault();
      resendCode();
    });

    const startOverBtn = document.getElementById('startOverBtn');
    if (startOverBtn) {
      startOverBtn.addEventListener('click', (event) => {
        event.preventDefault();
        resetSignupFlow();
        showMessage('Signup restarted. Please enter your details.', 'info');
      });
    }

    els.verifyCodeBtn?.addEventListener('click', (event) => {
      event.preventDefault();
      verifyCode();
    });

    els.setPasswordBtn?.addEventListener('click', (event) => {
      event.preventDefault();
      setPassword();
    });

    document.addEventListener('keydown', (event) => {
      if (event.key === 'Escape' && els.authModal?.classList.contains('is-open')) {
        closeModal();
      }
    });
  }

  function cacheElements() {
    els.authModal = byId('authModal');
    els.authMessage = byId('authMessage');
    els.authOpenBtn = byId('authOpenBtn');
    els.accountButton = byId('accountButton');
    els.logoutBtn = byId('logoutBtn');
    els.loginForm = byId('loginForm');
    els.signupForm = byId('signupForm');
    els.loginEmail = byId('loginEmail');
    els.loginPassword = byId('loginPassword');
    els.signupName = byId('signupName');
    els.signupEmail = byId('signupEmail');
    els.verificationCode = byId('verificationCode');
    els.signupPassword = byId('signupPassword');
    els.signupPasswordConfirm = byId('signupPasswordConfirm');
    els.sendCodeBtn = byId('sendCodeBtn');
    els.verifyCodeBtn = byId('verifyCodeBtn');
    els.resendCodeBtn = byId('resendCodeBtn');
    els.setPasswordBtn = byId('setPasswordBtn');
  }

  function init() {
    cacheElements();
    if (!els.authModal) return;
    bindEvents();
    updateHeaderState(readStoredUser());
    const savedState = readSignupState();
    if (savedState && typeof savedState === 'object') {
      state.mode = savedState.mode === 'signup' ? 'signup' : 'login';
      state.signupStep = savedState.signupStep || 'details';
      state.pendingEmail = savedState.pendingEmail || '';
      state.pendingName = savedState.pendingName || '';
      state.codeExpiresAt = savedState.codeExpiresAt || 0;
      state.resendAvailableAt = savedState.resendAvailableAt || 0;
    }

    renderSignupStep(state.signupStep || 'details');
    setMode(state.mode || 'login');




    validateSession();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
