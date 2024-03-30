const _iconPrefix = "assets/icons";
// bbc.png
final Map<String, String> _hostIconsAssetPath = {
  "cn.nytimes.com": "$_iconPrefix/nytimes.png",
  "www.nytimes.com": "$_iconPrefix/nytimes.png",
  "www.economist.com": "$_iconPrefix/theeconomist.png",
  "www.cnbc.com": "$_iconPrefix/cnbc.png",
  "www.nbcnews.com": "$_iconPrefix/cnbc.png",
  "www.chinadaily.com.cn": "$_iconPrefix/chinadaily.png",
  "www.bbc.com": "$_iconPrefix/bbc.png",
  "www.bbc.co.uk": "$_iconPrefix/bbc.png",
  "www.thetimes.co.uk": "$_iconPrefix/thetimes.png",
  "edition.cnn.com": "$_iconPrefix/cnn.png",
  "www.9news.com.au": "$_iconPrefix/9news.png",
  "www.washingtonpost.com": "$_iconPrefix/wp.png",
  "www.foxnews.com": "$_iconPrefix/foxnews.png",
  "apnews.com": "$_iconPrefix/ap.png",
  "www.npr.org": "$_iconPrefix/ap.png",
  "www.theguardian.com": "$_iconPrefix/theguardian.png",
  "www.voanews.com": "$_iconPrefix/voanews.png",
};

String assetPathByHost(String host) {
  return _hostIconsAssetPath[host] ?? "";
}
