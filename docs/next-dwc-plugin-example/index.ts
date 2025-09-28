/**
 * NeXT Dialog Override Plugin
 * 
 * This plugin replaces DWC's built-in MessageBoxDialog component to provide
 * persistent dialog display for NeXT dialogs while maintaining compatibility
 * with standard M291 dialogs.
 */

import Vue from "vue";
import NeXTMessageBoxDialog from "./components/NeXTMessageBoxDialog.vue";

// Replace the built-in message-box-dialog component with our custom version
Vue.component("message-box-dialog", NeXTMessageBoxDialog);

console.log("NeXT Dialog Override Plugin loaded");