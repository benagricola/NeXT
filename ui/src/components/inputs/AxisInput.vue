<template>
    <v-row dense>
        <v-col v-for="axis in visibleAxes" :key="axis.letter" :cols="axisColumns">
            <v-text-field
                :value="axisValues[axis.letter]"
                :label="axis.letter"
                :disabled="disabled || uiFrozen"
                type="number"
                step="0.001"
                outlined
                dense
                hide-details
                @input="updateAxis(axis.letter, $event)"
                @keydown.enter="$emit('enter', axisValues)"
            >
                <template v-slot:append>
                    <v-btn 
                        icon 
                        x-small 
                        :disabled="disabled || uiFrozen"
                        @click="setAxisToZero(axis.letter)"
                        title="Set to 0"
                    >
                        <v-icon small>mdi-numeric-0</v-icon>
                    </v-btn>
                </template>
            </v-text-field>
        </v-col>
    </v-row>
</template>

<script>
import BaseComponent from '../base/BaseComponent.vue';

export default {
    name: 'NxtAxisInput',
    extends: BaseComponent,
    props: {
        value: {
            type: Object,
            default: () => ({})
        },
        disabled: {
            type: Boolean,
            default: false
        },
        axes: {
            type: Array,
            default: () => ['X', 'Y', 'Z']
        }
    },

    data() {
        return {
            axisValues: { ...this.value }
        };
    },

    computed: {
        visibleAxes() {
            return this.axes
                .filter(letter => this.hasAxis(letter))
                .map(letter => ({ 
                    letter, 
                    ...this.visibleAxesByLetter[letter] 
                }));
        },

        axisColumns() {
            const count = this.visibleAxes.length;
            if (count <= 3) return 12 / count;
            return 3; // 4 per row for more than 3 axes
        }
    },

    watch: {
        value: {
            handler(newVal) {
                this.axisValues = { ...newVal };
            },
            deep: true
        },

        axisValues: {
            handler(newVal) {
                this.$emit('input', newVal);
            },
            deep: true
        }
    },

    methods: {
        updateAxis(axis, value) {
            const numValue = parseFloat(value);
            if (!isNaN(numValue)) {
                this.$set(this.axisValues, axis, numValue);
            } else if (value === '' || value === null) {
                this.$set(this.axisValues, axis, 0);
            }
        },

        setAxisToZero(axis) {
            this.$set(this.axisValues, axis, 0);
        }
    }
};
</script>