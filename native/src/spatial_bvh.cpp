// Implementation of Spigot 3D Bounding Volume Hierarchy

#include "spatial_bvh.hpp"
#include <algorithm>

namespace spigot {

bool Box::intersects(const Box& other) const noexcept {
    if (max.x < other.min.x || min.x > other.max.x) return false;
    if (max.y < other.min.y || min.y > other.max.y) return false;
    if (max.z < other.min.z || min.z > other.max.z) return false;
    return true;
}

bool Box::contains(const Vec3& pt) const noexcept {
    return (pt.x >= min.x && pt.x <= max.x &&
            pt.y >= min.y && pt.y <= max.y &&
            pt.z >= min.z && pt.z <= max.z);
}

void SpatialBVH::insert(const Box& box) {
    items_.push_back(box);
}

void SpatialBVH::clear() {
    items_.clear();
    root_.reset();
}

void SpatialBVH::build() {
    if (items_.empty()) return;
    std::vector<Box> boxes = items_;
    root_ = build_recursive(boxes, 0);
}

std::unique_ptr<SpatialBVH::Node> SpatialBVH::build_recursive(std::vector<Box>& boxes, size_t depth) {
    auto node = std::make_unique<Node>();
    if (boxes.empty()) return node;

    // Compute enclosing bounding box
    Vec3 b_min = boxes[0].min;
    Vec3 b_max = boxes[0].max;
    for (const auto& b : boxes) {
        b_min.x = std::min(b_min.x, b.min.x);
        b_min.y = std::min(b_min.y, b.min.y);
        b_min.z = std::min(b_min.z, b.min.z);
        b_max.x = std::max(b_max.x, b.max.x);
        b_max.y = std::max(b_max.y, b.max.y);
        b_max.z = std::max(b_max.z, b.max.z);
    }
    node->bounds = Box{b_min, b_max, "NODE"};

    if (boxes.size() <= 2 || depth >= 16) {
        node->items = boxes;
        node->is_leaf = true;
        return node;
    }

    node->is_leaf = false;
    size_t axis = depth % 3; // Cycle X, Y, Z

    auto comparator = [axis](const Box& a, const Box& b) {
        double ca = (axis == 0) ? (a.min.x + a.max.x) : ((axis == 1) ? (a.min.y + a.max.y) : (a.min.z + a.max.z));
        double cb = (axis == 0) ? (b.min.x + b.max.x) : ((axis == 1) ? (b.min.y + b.max.y) : (b.min.z + b.max.z));
        return ca < cb;
    };

    std::sort(boxes.begin(), boxes.end(), comparator);
    size_t mid = boxes.size() / 2;

    std::vector<Box> left_boxes(boxes.begin(), boxes.begin() + mid);
    std::vector<Box> right_boxes(boxes.begin() + mid, boxes.end());

    node->left = build_recursive(left_boxes, depth + 1);
    node->right = build_recursive(right_boxes, depth + 1);

    return node;
}

std::optional<std::string> SpatialBVH::query_collision(const Box& test_box) const {
    if (!root_) return std::nullopt;
    std::string hit_label;
    if (query_recursive(root_.get(), test_box, hit_label)) {
        return hit_label;
    }
    return std::nullopt;
}

bool SpatialBVH::query_recursive(const Node* node, const Box& test_box, std::string& hit_label) const {
    if (!node || !node->bounds.intersects(test_box)) {
        return false;
    }

    if (node->is_leaf) {
        for (const auto& item : node->items) {
            if (item.intersects(test_box)) {
                hit_label = item.label;
                return true;
            }
        }
        return false;
    }

    if (query_recursive(node->left.get(), test_box, hit_label)) return true;
    if (query_recursive(node->right.get(), test_box, hit_label)) return true;
    return false;
}

} // namespace spigot
