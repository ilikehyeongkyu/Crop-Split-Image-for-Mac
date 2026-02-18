import ProjectDescription

let project = Project(
    name: "CropSplitImage",
    organizationName: "com.hyeongkyu",
    targets: [
        Target.target(
            name: "CropSplitImageApp",
            destinations: .macOS,
            product: Product.app,
            bundleId: "com.hyeongkyu.CropSplitImageApp",
            infoPlist: InfoPlist.default,
            sources: ["Sources/CropSplitApp/**"],
            resources: []
        )
    ]
)
