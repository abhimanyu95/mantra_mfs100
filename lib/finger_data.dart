class FingerData {

  final List<int> fingerImage;

  final int quality;

  final int nfiq;

  final List<int> rawData;

  final List<int> iSOTemplate;

  final double inWidth;

  final double inHeight;

  final double inArea;

  final double resolution;

  final int grayScale;

  final int bpp;

  final double wSQCompressRatio;

  final String wSQInfo;

  FingerData({
    required this.fingerImage,
    required this.quality,
    required this.nfiq,
    required this.rawData,
    required this.iSOTemplate,
    required this.inWidth,
    required this.inHeight,
    required this.inArea,
    required this.resolution,
    required this.grayScale,
    required this.bpp,
    required this.wSQCompressRatio,
    required this.wSQInfo,
  });

  factory FingerData.load(Map<dynamic, dynamic> data){

    return FingerData(
        fingerImage: data['finger_image'],
        quality: data['quality'],
        nfiq: data['nfiq'],
        rawData: data['raw_data'],
        iSOTemplate: data['iso_template'],
        inWidth: data['in_width'],
        inHeight: data['in_height'],
        inArea: data['in_area'],
        resolution: data['resolution'],
        grayScale: data['greyscale'],
        bpp: data['bpp'],
        wSQCompressRatio: data['wsq_compress_ratio'],
        wSQInfo: data['wsq_info']
    );
  }

}
