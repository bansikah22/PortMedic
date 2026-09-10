const ICON_DATA: &[u8] = include_bytes!("../assets/portmedic.png");

pub fn rgba() -> Option<(Vec<u8>, u32, u32)> {
    let image = image::load_from_memory(ICON_DATA).ok()?.to_rgba8();
    let (width, height) = image.dimensions();
    Some((image.into_raw(), width, height))
}
