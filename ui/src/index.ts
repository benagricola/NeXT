import { registerRoute, registerPluginLocalization, registerPluginData } from '@duet3d/objectmodel-plugin';

// Import localization
import en from './locales/en.json';

// Import main component
import NeXT from './NeXT.vue';

// Import all component files to register them
import './components';

// Register plugin localization
registerPluginLocalization(en);

// Register plugin data in machine cache for persistent state
registerPluginData('nxtUiReady', true);

// Register main NeXT route under Control menu
registerRoute(NeXT, {
    Control: {
        NeXT: {
            icon: 'mdi-cog',
            component: NeXT,
            condition: () => true
        }
    }
});