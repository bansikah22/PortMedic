const ICON_DATA: &[u8] = include_bytes!("../assets/portmedic.png");
const MAX_ICON_DIMENSION: u32 = 4096;

pub fn rgba() -> Option<(Vec<u8>, u32, u32)> {
    let image = image::load_from_memory(ICON_DATA).ok()?.to_rgba8();
    let (width, height) = image.dimensions();

    if width == 0 || height == 0 || width > MAX_ICON_DIMENSION || height > MAX_ICON_DIMENSION {
        return None;
    }

    Some((image.into_raw(), width, height))
}
