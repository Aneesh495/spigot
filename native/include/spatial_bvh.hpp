// Spigot C++ Native Spatial Bounding Volume Hierarchy (BVH)
// Accelerates deck collision queries and ray-intersection tests across dense labware.

#ifndef SPIGOT_SPATIAL_BVH_HPP
#define SPIGOT_SPATIAL_BVH_HPP

#include <vector>
#include <string>
#include <memory>
#include <optional>

namespace spigot {

struct Vec3 {
    double x{0.0};
    double y{0.0};
    double z{0.0};
};

struct Box {
    Vec3 min;
    Vec3 max;
    std::string label;

    [[nodiscard]] bool intersects(const Box& other) const noexcept;
    [[nodiscard]] bool contains(const Vec3& pt) const noexcept;
};

class SpatialBVH {
public:
    struct Node {
        Box bounds;
        std::unique_ptr<Node> left;
        std::unique_ptr<Node> right;
        std::vector<Box> items;
        bool is_leaf{true};
    };

    SpatialBVH() = default;

    // Adds a static obstacle bounding box to the dataset
    void insert(const Box& box);

    // Builds the hierarchical tree structure
    void build();

    // Queries whether an AABB intersects any obstacle in the BVH
    [[nodiscard]] std::optional<std::string> query_collision(const Box& test_box) const;

    // Clears all nodes and items
    void clear();

    [[nodiscard]] size_t size() const noexcept { return items_.size(); }

private:
    std::vector<Box> items_;
    std::unique_ptr<Node> root_;

    std::unique_ptr<Node> build_recursive(std::vector<Box>& boxes, size_t depth);
    bool query_recursive(const Node* node, const Box& test_box, std::string& hit_label) const;
};

} // namespace spigot

#endif // SPIGOT_SPATIAL_BVH_HPP
