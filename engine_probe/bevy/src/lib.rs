//! DRAGON REALMS — motor araştırma probu (Bevy 0.20, Android ARM64).
//!
//! Bu uygulama yalnizca GitHub Actions üzerinde gerçek bir ARM64 APK
//! üretilebildiğini kanıtlamak için yazılmıştır. PBR malzeme + gölge + kamera
//! içeren küçük bir 3D sahne kurar.

use bevy::prelude::*;
use bevy::window::{MonitorSelection, WindowMode};

// `bevy_main` makrosu Android için gerekli `android_main` boilerplate'ini üretir
#[bevy_main]
pub fn main() {
    App::new()
        .add_plugins(
            DefaultPlugins.set(WindowPlugin {
                primary_window: Some(Window {
                    resizable: false,
                    mode: WindowMode::BorderlessFullscreen(MonitorSelection::Primary),
                    ..default()
                }),
                ..default()
            }),
        )
        .add_systems(Startup, setup)
        .run();
}

fn setup(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut materials: ResMut<Assets<StandardMaterial>>,
) {
    // Kırmızı küp (PBR malzeme)
    commands.spawn((
        Mesh3d(meshes.add(Cuboid::new(2.0, 2.0, 2.0))),
        MeshMaterial3d(materials.add(Color::srgb_u8(200, 60, 40))),
        Transform::default(),
    ));
    // Işık + gölge
    commands.spawn((
        PointLight {
            shadow_maps_enabled: true,
            ..default()
        },
        Transform::from_xyz(4.0, 8.0, 4.0),
    ));
    // Kamera
    commands.spawn((
        Camera3d::default(),
        Transform::from_xyz(0.0, 2.0, 8.0).looking_at(Vec3::ZERO, Dir3::Y),
    ));
    commands.insert_resource(ClearColor(Color::srgb_u8(12, 16, 30)));
}
