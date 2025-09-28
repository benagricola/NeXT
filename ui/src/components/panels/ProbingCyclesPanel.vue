<template>
    <v-card class="nxt-probing-cycles">
        <v-card-title>
            <v-icon left color="primary">mdi-wrench</v-icon>
            {{ $t('NeXT.probing.cycles') }}
        </v-card-title>

        <v-card-text>
            <v-alert v-if="!allAxesHomed" type="warning" dense outlined class="mb-3">
                <v-icon left>mdi-alert</v-icon>
                All axes must be homed before probing.
            </v-alert>

            <v-alert v-if="!probeTool" type="error" dense outlined class="mb-3">
                <v-icon left>mdi-alert-circle</v-icon>
                No probe tool configured. Check NeXT configuration.
            </v-alert>

            <div class="probing-grid">
                <!-- Feature Probing -->
                <v-card outlined class="ma-1">
                    <v-card-subtitle>Feature Probing</v-card-subtitle>
                    <v-card-text class="pt-0">
                        <v-row dense>
                            <v-col cols="6">
                                <v-btn 
                                    block small
                                    :disabled="!canProbe"
                                    @click="startProbing('G6500')"
                                >
                                    Bore (G6500)
                                </v-btn>
                            </v-col>
                            <v-col cols="6">
                                <v-btn 
                                    block small
                                    :disabled="!canProbe"
                                    @click="startProbing('G6501')"
                                >
                                    Boss (G6501)
                                </v-btn>
                            </v-col>
                            <v-col cols="6">
                                <v-btn 
                                    block small
                                    :disabled="!canProbe"
                                    @click="startProbing('G6502')"
                                >
                                    Rect Pocket (G6502)
                                </v-btn>
                            </v-col>
                            <v-col cols="6">
                                <v-btn 
                                    block small
                                    :disabled="!canProbe"
                                    @click="startProbing('G6503')"
                                >
                                    Rect Block (G6503)
                                </v-btn>
                            </v-col>
                        </v-row>
                    </v-card-text>
                </v-card>

                <!-- Surface Probing -->
                <v-card outlined class="ma-1">
                    <v-card-subtitle>Surface Probing</v-card-subtitle>
                    <v-card-text class="pt-0">
                        <v-row dense>
                            <v-col cols="6">
                                <v-btn 
                                    block small
                                    :disabled="!canProbe"
                                    @click="startProbing('G6504')"
                                >
                                    Web X/Y (G6504)
                                </v-btn>
                            </v-col>
                            <v-col cols="6">
                                <v-btn 
                                    block small
                                    :disabled="!canProbe"
                                    @click="startProbing('G6505')"
                                >
                                    Pocket X/Y (G6505)
                                </v-btn>
                            </v-col>
                            <v-col cols="6">
                                <v-btn 
                                    block small
                                    :disabled="!canProbe"
                                    @click="startProbing('G6510')"
                                >
                                    Single Surface (G6510)
                                </v-btn>
                            </v-col>
                            <v-col cols="6">
                                <v-btn 
                                    block small
                                    :disabled="!canProbe"
                                    @click="startProbing('G6520')"
                                >
                                    Vise Corner (G6520)
                                </v-btn>
                            </v-col>
                        </v-row>
                    </v-card-text>
                </v-card>

                <!-- Corner Probing -->
                <v-card outlined class="ma-1">
                    <v-card-subtitle>Corner Probing</v-card-subtitle>
                    <v-card-text class="pt-0">
                        <v-row dense>
                            <v-col cols="6">
                                <v-btn 
                                    block small
                                    :disabled="!canProbe"
                                    @click="startProbing('G6508')"
                                >
                                    Outside Corner (G6508)
                                </v-btn>
                            </v-col>
                            <v-col cols="6">
                                <v-btn 
                                    block small
                                    :disabled="!canProbe"
                                    @click="startProbing('G6509')"
                                >
                                    Inside Corner (G6509)
                                </v-btn>
                            </v-col>
                        </v-row>
                    </v-card-text>
                </v-card>
            </div>
        </v-card-text>

        <!-- Probing Configuration Dialog -->
        <v-dialog v-model="probingDialog" max-width="500">
            <v-card>
                <v-card-title>
                    Configure {{ selectedCycle }}
                </v-card-title>
                <v-card-text>
                    <v-form ref="probingForm" v-model="formValid">
                        <!-- Common parameters -->
                        <v-text-field
                            v-model.number="probingParams.feedrate"
                            label="Probing Feedrate (mm/min)"
                            type="number"
                            min="1"
                            max="1000"
                            :rules="[rules.required, rules.positive]"
                            outlined
                            dense
                        />
                        
                        <v-text-field
                            v-model.number="probingParams.distance"
                            label="Maximum Probe Distance (mm)"
                            type="number"
                            min="0.1"
                            max="100"
                            :rules="[rules.required, rules.positive]"
                            outlined
                            dense
                        />

                        <!-- Cycle-specific parameters would go here -->
                        <!-- This would be expanded based on the selected cycle -->
                    </v-form>
                </v-card-text>
                <v-card-actions>
                    <v-spacer />
                    <v-btn text @click="probingDialog = false">Cancel</v-btn>
                    <v-btn 
                        color="primary" 
                        :disabled="!formValid || uiFrozen"
                        @click="executeProbing"
                    >
                        Start Probing
                    </v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>
    </v-card>
</template>

<script>
import BaseComponent from '../base/BaseComponent.vue';

export default {
    name: 'NxtProbingCyclesPanel',
    extends: BaseComponent,
    data() {
        return {
            probingDialog: false,
            selectedCycle: null,
            formValid: false,
            probingParams: {
                feedrate: 100,
                distance: 10
            },
            rules: {
                required: value => !!value || 'Required',
                positive: value => value > 0 || 'Must be positive'
            }
        };
    },

    computed: {
        canProbe() {
            return this.allAxesHomed && 
                   this.probeTool && 
                   !this.uiFrozen &&
                   this.nxtLoaded;
        }
    },

    methods: {
        startProbing(cycleCode) {
            this.selectedCycle = cycleCode;
            this.probingDialog = true;
        },

        executeProbing() {
            if (!this.formValid) return;

            // Build G-code command with parameters
            let gcode = this.selectedCycle;
            gcode += ` F${this.probingParams.feedrate}`;
            gcode += ` R${this.probingParams.distance}`;
            
            // Add cycle-specific parameters as needed
            // This would be expanded based on the cycle requirements

            this.sendCode(gcode);
            this.probingDialog = false;
            
            // Reset form for next use
            this.$refs.probingForm.reset();
        }
    }
};
</script>

<style scoped>
.probing-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 8px;
}

.probing-grid .v-card {
    min-height: 150px;
}
</style>