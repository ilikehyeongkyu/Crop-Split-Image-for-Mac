import ProjectDescription

let project = Project(
    name: "CropSplitImage",
    organizationName: "net.hyeongkyu",
    targets: [
        Target.target(
            name: "CropSplitImageApp",
            destinations: .macOS,
            product: Product.app,
            bundleId: "net.hyeongkyu.CropSplitImageApp",
            infoPlist: .file(path: "Resources/Info.plist"),
            sources: ["Sources/CropSplitApp/**"],
            resources: ["Resources/**"]
        )
    ]
)
