<template>
    <v-card class="nxt-configuration">
        <v-card-title>
            <v-icon left color="primary">mdi-cog</v-icon>
            {{ $t('NeXT.configuration.title') }}
        </v-card-title>

        <v-card-text>
            <v-expansion-panels v-model="openPanels" multiple>
                <!-- Probe Settings -->
                <v-expansion-panel>
                    <v-expansion-panel-header>
                        <v-icon left>mdi-crosshairs</v-icon>
                        Probe Settings
                    </v-expansion-panel-header>
                    <v-expansion-panel-content>
                        <v-form ref="probeForm" v-model="probeFormValid">
                            <v-row>
                                <v-col cols="12" md="6">
                                    <v-text-field
                                        v-model.number="probeSettings.deflection"
                                        :label="$t('NeXT.configuration.probeDeflection') + ' (mm)'"
                                        type="number"
                                        step="0.001"
                                        min="0"
                                        max="1"
                                        :rules="[rules.required, rules.nonNegative]"
                                        outlined
                                        dense
                                        @change="updateProbeSetting('deflection', $event)"
                                    />
                                </v-col>
                                <v-col cols="12" md="6">
                                    <v-text-field
                                        v-model.number="probeSettings.tipRadius"
                                        :label="$t('NeXT.configuration.probeTipRadius') + ' (mm)'"
                                        type="number"
                                        step="0.001"
                                        min="0"
                                        max="10"
                                        :rules="[rules.required, rules.nonNegative]"
                                        outlined
                                        dense
                                        @change="updateProbeSetting('tipRadius', $event)"
                                    />
                                </v-col>
                            </v-row>
                            
                            <v-row>
                                <v-col cols="12">
                                    <v-btn
                                        color="primary"
                                        :disabled="uiFrozen"
                                        @click="measureDeflection"
                                    >
                                        <v-icon left>mdi-ruler</v-icon>
                                        Measure Probe Deflection
                                    </v-btn>
                                </v-col>
                            </v-row>
                        </v-form>
                    </v-expansion-panel-content>
                </v-expansion-panel>

                <!-- Machine Settings -->
                <v-expansion-panel>
                    <v-expansion-panel-header>
                        <v-icon left>mdi-cog-outline</v-icon>
                        Machine Settings
                    </v-expansion-panel-header>
                    <v-expansion-panel-content>
                        <v-form ref="machineForm" v-model="machineFormValid">
                            <v-row>
                                <v-col cols="12" md="6">
                                    <v-text-field
                                        v-model.number="machineSettings.parkX"
                                        label="Park Position X (mm)"
                                        type="number"
                                        :rules="[rules.required]"
                                        outlined
                                        dense
                                        @change="updateMachineSetting('parkX', $event)"
                                    />
                                </v-col>
                                <v-col cols="12" md="6">
                                    <v-text-field
                                        v-model.number="machineSettings.parkY"
                                        label="Park Position Y (mm)"
                                        type="number"
                                        :rules="[rules.required]"
                                        outlined
                                        dense
                                        @change="updateMachineSetting('parkY', $event)"
                                    />
                                </v-col>
                                <v-col cols="12" md="6">
                                    <v-text-field
                                        v-model.number="machineSettings.parkZ"
                                        label="Park Position Z (mm)"
                                        type="number"
                                        :rules="[rules.required]"
                                        outlined
                                        dense
                                        @change="updateMachineSetting('parkZ', $event)"
                                    />
                                </v-col>
                                <v-col cols="12" md="6">
                                    <v-text-field
                                        v-model.number="machineSettings.safeZ"
                                        label="Safe Z Height (mm)"
                                        type="number"
                                        :rules="[rules.required]"
                                        outlined
                                        dense
                                        @change="updateMachineSetting('safeZ', $event)"
                                    />
                                </v-col>
                            </v-row>
                        </v-form>
                    </v-expansion-panel-content>
                </v-expansion-panel>

                <!-- Tool Settings -->
                <v-expansion-panel>
                    <v-expansion-panel-header>
                        <v-icon left>mdi-wrench</v-icon>
                        Tool Settings
                    </v-expansion-panel-header>
                    <v-expansion-panel-content>
                        <v-form ref="toolForm" v-model="toolFormValid">
                            <v-row>
                                <v-col cols="12" md="6">
                                    <v-text-field
                                        v-model.number="toolSettings.probeToolId"
                                        label="Probe Tool ID"
                                        type="number"
                                        min="0"
                                        max="255"
                                        :rules="[rules.required, rules.nonNegative]"
                                        outlined
                                        dense
                                        @change="updateToolSetting('probeToolId', $event)"
                                    />
                                </v-col>
                                <v-col cols="12" md="6">
                                    <v-switch
                                        v-model="toolSettings.useToolSetter"
                                        label="Use Tool Setter"
                                        @change="updateToolSetting('useToolSetter', $event)"
                                    />
                                </v-col>
                            </v-row>
                        </v-form>
                    </v-expansion-panel-content>
                </v-expansion-panel>
            </v-expansion-panels>

            <v-row class="mt-4">
                <v-col cols="12">
                    <v-btn
                        color="success"
                        block
                        large
                        :disabled="!allFormsValid || uiFrozen"
                        @click="saveConfiguration"
                    >
                        <v-icon left>mdi-content-save</v-icon>
                        Save Configuration
                    </v-btn>
                </v-col>
            </v-row>
        </v-card-text>
    </v-card>
</template>

<script>
import BaseComponent from '../base/BaseComponent.vue';

export default {
    name: 'NxtConfigurationPanel',
    extends: BaseComponent,
    data() {
        return {
            openPanels: [0], // Open first panel by default
            probeFormValid: false,
            machineFormValid: false,
            toolFormValid: false,
            probeSettings: {
                deflection: 0.02,
                tipRadius: 1.0
            },
            machineSettings: {
                parkX: 0,
                parkY: 0,
                parkZ: 10,
                safeZ: 5
            },
            toolSettings: {
                probeToolId: 99,
                useToolSetter: true
            },
            rules: {
                required: value => value !== null && value !== undefined && value !== '' || 'Required',
                nonNegative: value => value >= 0 || 'Must be non-negative'
            }
        };
    },

    computed: {
        allFormsValid() {
            return this.probeFormValid && this.machineFormValid && this.toolFormValid;
        }
    },

    mounted() {
        // Load current settings from global variables
        this.loadConfiguration();
    },

    methods: {
        loadConfiguration() {
            // Load probe settings from global variables
            const globals = this.$store.state.machine.model.global || {};
            
            if (globals.nxtProbeDeflection !== undefined) {
                this.probeSettings.deflection = globals.nxtProbeDeflection;
            }
            if (globals.nxtProbeTipRadius !== undefined) {
                this.probeSettings.tipRadius = globals.nxtProbeTipRadius;
            }
            if (globals.nxtProbeToolId !== undefined) {
                this.toolSettings.probeToolId = globals.nxtProbeToolId;
            }
            
            // Load machine settings
            if (globals.nxtParkPosition) {
                this.machineSettings.parkX = globals.nxtParkPosition[0] || 0;
                this.machineSettings.parkY = globals.nxtParkPosition[1] || 0;
                this.machineSettings.parkZ = globals.nxtParkPosition[2] || 10;
            }
            if (globals.nxtSafeZ !== undefined) {
                this.machineSettings.safeZ = globals.nxtSafeZ;
            }
        },

        updateProbeSetting(key, value) {
            this.sendCode(`set global.nxtProbe${key.charAt(0).toUpperCase() + key.slice(1)} = ${value}`);
        },

        updateMachineSetting(key, value) {
            if (key.startsWith('park')) {
                // Update park position vector
                const parkPos = [
                    this.machineSettings.parkX,
                    this.machineSettings.parkY,
                    this.machineSettings.parkZ
                ];
                this.sendCode(`set global.nxtParkPosition = {${parkPos.join(', ')}}`);
            } else {
                this.sendCode(`set global.nxt${key.charAt(0).toUpperCase() + key.slice(1)} = ${value}`);
            }
        },

        updateToolSetting(key, value) {
            this.sendCode(`set global.nxt${key.charAt(0).toUpperCase() + key.slice(1)} = ${value}`);
        },

        measureDeflection() {
            // Trigger probe deflection measurement macro
            this.sendCode('M98 P"macros/probing/measure-deflection.g"');
        },

        saveConfiguration() {
            // Save all settings to nxt-user-vars.g file
            this.sendCode('M98 P"macros/system/save-config.g"');
            
            // Show success message
            this.$emit('configuration-saved');
        }
    }
};
</script>

<style scoped>
.nxt-configuration .v-expansion-panel-content >>> .v-expansion-panel-content__wrap {
    padding: 16px;
}
</style>