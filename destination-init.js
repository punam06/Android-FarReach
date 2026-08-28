// Simple initialization loader - works around the issue where destination.js isn't executing
console.log('[destination-init.js] Loading...');

// Load destination.js as text and eval it
(async function() {
  try {
    console.log('[destination-init.js] Fetching destination.js...');
    const response = await fetch('destination.js');
    if (!response.ok) {
      throw new Error('Failed to fetch destination.js: ' + response.status);
    }
    
    const code = await response.text();
    console.log('[destination-init.js] Got code, length:', code.length);
    
    // Execute the code in global scope
    console.log('[destination-init.js] Executing destination.js code...');
    eval(code);
    
    console.log('[destination-init.js] Code executed successfully');
    console.log('[destination-init.js] initDestinationPage type:', typeof initDestinationPage);
    
    // If page is already loaded, initialize
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', () => {
        console.log('[destination-init.js] DOMContentLoaded, initializing...');
        if (typeof initDestinationPage === 'function') {
          initDestinationPage().catch(err => {
            console.error('[destination-init.js] Error in initDestinationPage:', err);
          });
        }
      });
    } else {
      // Page already loaded
      console.log('[destination-init.js] Document already loaded, initializing immediately...');
      if (typeof initDestinationPage === 'function') {
        initDestinationPage().catch(err => {
          console.error('[destination-init.js] Error in initDestinationPage:', err);
        });
      }
    }
  } catch (err) {
    console.error('[destination-init.js] Failed to initialize:', err.message);
    console.error(err.stack);
  }
})();
