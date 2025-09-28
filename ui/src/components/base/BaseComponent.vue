<template>
    <!-- This is a base component providing common functionality -->
    <div></div>
</template>

<script>
export default {
    name: 'BaseComponent',
    computed: {
        // Check if UI is temporarily frozen (during macro execution)
        uiFrozen() {
            return this.$store.state.machine.status === 'processing' || 
                   this.$store.state.machine.status === 'busy';
        },

        // Check if all visible axes are homed
        allAxesHomed() {
            const axes = this.$store.state.machine.model.move.axes;
            const visibleAxes = axes.filter(axis => axis.visible);
            return visibleAxes.every(axis => axis.homed);
        },

        // Get visible axes mapped by letter
        visibleAxesByLetter() {
            const axes = this.$store.state.machine.model.move.axes;
            const result = {};
            axes.forEach((axis, index) => {
                if (axis.visible) {
                    result[axis.letter] = {
                        index,
                        ...axis
                    };
                }
            });
            return result;
        },

        // Get current tool information
        currentTool() {
            const toolNumber = this.$store.state.machine.model.state.currentTool;
            if (toolNumber >= 0) {
                return this.$store.state.machine.model.tools[toolNumber];
            }
            return null;
        },

        // Get probe tool based on global.nxtProbeToolId
        probeTool() {
            const probeToolId = this.$store.state.machine.model.global?.nxtProbeToolId;
            if (probeToolId >= 0) {
                return this.$store.state.machine.model.tools[probeToolId];
            }
            return null;
        },

        // Get/Set current Work Coordinate System
        currentWorkplace: {
            get() {
                return this.$store.state.machine.model.move.workplaceNumber || 1;
            },
            set(value) {
                this.sendCode(`G${53 + parseInt(value)}`);
            }
        },

        // Calculate absolute machine position for visible axes
        absolutePosition() {
            const machinePosition = this.$store.state.machine.model.move.machinePosition;
            const workplaceOffsets = this.$store.state.machine.model.move.workplaceOffsets;
            const currentWcs = this.currentWorkplace - 1;
            const result = {};

            Object.keys(this.visibleAxesByLetter).forEach(letter => {
                const axisIndex = this.visibleAxesByLetter[letter].index;
                const machinePos = machinePosition[axisIndex] || 0;
                const offset = (workplaceOffsets[currentWcs] && workplaceOffsets[currentWcs][axisIndex]) || 0;
                result[letter] = machinePos - offset;
            });

            return result;
        },

        // Check if NeXT is loaded and ready
        nxtLoaded() {
            return this.$store.state.machine.model.global?.nxtLoaded === true;
        },

        // Get NeXT version
        nxtVersion() {
            return this.$store.state.machine.model.global?.nxtVersion || 'Unknown';
        }
    },

    methods: {
        // Send G-code command to machine
        sendCode(code) {
            this.$store.dispatch('machine/sendCode', code);
        },

        // Format coordinate display with appropriate precision
        formatCoordinate(value, precision = 3) {
            if (typeof value !== 'number') return '---';
            return value.toFixed(precision);
        },

        // Check if a specific axis exists and is visible
        hasAxis(letter) {
            return letter in this.visibleAxesByLetter;
        }
    }
};
</script>