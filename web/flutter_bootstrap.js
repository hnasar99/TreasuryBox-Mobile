{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    try {
      const appRunner = await engineInitializer.initializeEngine();
      await appRunner.runApp();
      document.getElementById('loading')?.remove();
    } catch (error) {
      const loading = document.getElementById('loading');
      if (loading) loading.textContent = 'TreasuryBox could not start. Please reload in an up-to-date browser.';
      console.error('TreasuryBox startup failed', error);
    }
  }
});
