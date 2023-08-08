// Spigot Multichannel Pipette Pitch Actuator
// Manages dynamic tip spacing adjustment across 96-well (9mm), 384-well (4.5mm), and tube (18mm) formats.

dofile("core/math.nut");

class MultiChannelPitchActuator {
    channel_count = 8;
    current_pitch_mm = 9.0;
    min_pitch_mm = 4.5;
    max_pitch_mm = 18.0;

    constructor(num_channels = 8, initial_pitch = 9.0) {
        channel_count = num_channels;
        current_pitch_mm = initial_pitch.tofloat();
    }

    function set_pitch(pitch_mm) {
        local p = pitch_mm.tofloat();
        if (p < min_pitch_mm || p > max_pitch_mm) {
            throw "PitchOutOfRangeException: Commanded pitch " + p + " mm is outside range [" + min_pitch_mm + ", " + max_pitch_mm + "] mm";
        }
        current_pitch_mm = p;
    }

    // Computes the 3D position of each tip channel given head anchor position (channel 0).
    function get_channel_positions(anchor_pos_channel_0) {
        local positions = [];
        for (local i = 0; i < channel_count; i++) {
            // Multichannel heads typically align along the Y axis
            local y_offset = i * current_pitch_mm;
            positions.append(Vector3(
                anchor_pos_channel_0.x,
                anchor_pos_channel_0.y + y_offset,
                anchor_pos_channel_0.z
            ));
        }
        return positions;
    }

    // Total span of the multichannel head from channel 0 to channel (N-1).
    function get_total_span_mm() {
        return (channel_count - 1) * current_pitch_mm;
    }
}
