<template>
    <v-card class="nxt-probe-results">
        <v-card-title>
            <v-icon left color="primary">mdi-crosshairs-gps</v-icon>
            {{ $t('NeXT.probing.results') }}
            <v-spacer />
            <v-btn small text @click="clearResults" :disabled="!hasResults">
                <v-icon small left>mdi-delete</v-icon>
                Clear
            </v-btn>
        </v-card-title>

        <v-card-text>
            <div v-if="!hasResults" class="text-center text--secondary py-4">
                No probe results available. Run a probing cycle to populate this table.
            </div>

            <v-data-table
                v-else
                :headers="tableHeaders"
                :items="probeResults"
                item-key="id"
                dense
                single-select
                v-model="selectedResult"
                show-select
                class="probe-results-table"
            >
                <!-- Coordinate columns -->
                <template v-slot:item.coordinates="{ item }">
                    <span v-for="(coord, axis) in item.coordinates" :key="axis" class="mr-2">
                        {{ axis }}{{ formatCoordinate(coord) }}
                    </span>
                </template>

                <!-- Timestamp column -->
                <template v-slot:item.timestamp="{ item }">
                    {{ formatTimestamp(item.timestamp) }}
                </template>

                <!-- Actions column -->
                <template v-slot:item.actions="{ item }">
                    <v-btn-group dense>
                        <v-btn 
                            small 
                            color="primary"
                            @click="pushToWcs(item)"
                            :disabled="uiFrozen"
                        >
                            <v-icon small>mdi-application-export</v-icon>
                        </v-btn>
                        <v-btn 
                            small 
                            color="secondary"
                            @click="selectForMerge(item)"
                            :disabled="uiFrozen"
                        >
                            <v-icon small>mdi-merge</v-icon>
                        </v-btn>
                    </v-btn-group>
                </template>
            </v-data-table>

            <!-- Action buttons -->
            <v-row class="mt-3" v-if="hasResults">
                <v-col cols="12" sm="6">
                    <v-select
                        v-model="targetWcs"
                        :items="wcsOptions"
                        label="Target WCS"
                        dense
                        outlined
                    />
                </v-col>
                <v-col cols="12" sm="6">
                    <v-btn
                        color="primary"
                        block
                        :disabled="!selectedResult.length || uiFrozen"
                        @click="pushSelectedToWcs"
                    >
                        {{ $t('NeXT.probing.pushToWcs') }}
                    </v-btn>
                </v-col>
            </v-row>
        </v-card-text>
    </v-card>
</template>

<script>
import BaseComponent from '../base/BaseComponent.vue';

export default {
    name: 'NxtProbeResultsPanel',
    extends: BaseComponent,
    data() {
        return {
            selectedResult: [],
            targetWcs: 54, // G54
            mergeTarget: null
        };
    },

    computed: {
        // Get probe results from global variables
        probeResultsRaw() {
            return this.$store.state.machine.model.global?.nxtProbeResults || [];
        },

        // Format probe results for display
        probeResults() {
            return this.probeResultsRaw.map((result, index) => ({
                id: index,
                type: result.type || 'Unknown',
                coordinates: result.coordinates || {},
                timestamp: result.timestamp || Date.now(),
                ...result
            }));
        },

        hasResults() {
            return this.probeResults.length > 0;
        },

        tableHeaders() {
            return [
                { text: 'Type', value: 'type', sortable: false },
                { text: 'Coordinates', value: 'coordinates', sortable: false },
                { text: 'Time', value: 'timestamp', sortable: true },
                { text: 'Actions', value: 'actions', sortable: false, width: '120px' }
            ];
        },

        wcsOptions() {
            return [
                { text: 'G54', value: 54 },
                { text: 'G55', value: 55 },
                { text: 'G56', value: 56 },
                { text: 'G57', value: 57 },
                { text: 'G58', value: 58 },
                { text: 'G59', value: 59 }
            ];
        }
    },

    methods: {
        formatTimestamp(timestamp) {
            return new Date(timestamp).toLocaleTimeString();
        },

        pushToWcs(result) {
            const wcsCode = `G${this.targetWcs}`;
            const coords = result.coordinates;
            
            // Build G-code command to set WCS origin
            let gcode = wcsCode;
            Object.keys(coords).forEach(axis => {
                gcode += ` ${axis}${coords[axis]}`;
            });
            
            this.sendCode(gcode);
            this.$emit('wcs-updated', { wcs: this.targetWcs, result });
        },

        pushSelectedToWcs() {
            if (this.selectedResult.length > 0) {
                this.pushToWcs(this.selectedResult[0]);
            }
        },

        selectForMerge(result) {
            this.mergeTarget = result;
            // TODO: Implement merge functionality
        },

        clearResults() {
            this.sendCode('set global.nxtProbeResults = {}');
            this.selectedResult = [];
        }
    }
};
</script>

<style scoped>
.probe-results-table {
    max-height: 400px;
}

.probe-results-table >>> .v-data-table__wrapper {
    overflow-y: auto;
}
</style>