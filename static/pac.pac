const countries = {"at":"HTTPS at2.edgecache.fun:3173","au":"HTTPS au19.rapidcdn.click:9280","be":"HTTPS be24.speedstream.info:1755","bg":"HTTPS bg3.cachequick.pro:12906","br":"HTTPS br4.contentboost.website:15490","ca":"HTTPS ca3.datadistribute.live:5418","ch":"HTTPS ch1.contentboost.click:20968","cl":"HTTPS cl2.quickcache.space:24201","cy":"HTTPS cy6.edgecache.fun:5717","cz":"HTTPS cz1.quickcache.click:13522","de":"HTTPS de3.cachequick.pro:6188","dk":"HTTPS dk1.cdnnetwork.fun:24445","es":"HTTPS es7.speedstream.info:23295","fi":"HTTPS fi231.rapidcdn.click:3682; HTTPS fi229.speedstream.click:2275; HTTPS fi225.speedstream.click:21927","fr":"HTTPS fr4.speedstream.live:7545","gr":"HTTPS gr5.streamlineddata.space:24853","hk":"HTTPS hk11.edgeaccelerator.website:11505","hr":"HTTPS hr1.rapidcdn.click:21331","hu":"HTTPS hu23.cdnaccelerate.xyz:15539","ie":"HTTPS ie1.edgecache.fun:3900","il":"HTTPS il1.cdnnetwork.fun:10027","in":"HTTPS in22.cdnexpress.live:2494","is":"HTTPS is5.cdnnetwork.live:22396","it":"HTTPS it3.fastcontent.live:23700","jp":"HTTPS jp26.streamlineddata.space:10001","kr":"HTTPS kr13.rapidcdn.click:9019","lt":"HTTPS lt1.cdnexpress.live:19213","lv":"HTTPS lv30.staticvaultcdn.org:443; HTTPS lv52.staticvaultcdn.xyz:443; HTTPS lv22.servefaststatic.work:443","mx":"HTTPS mx2.cdnnetwork.fun:1494","nl":"HTTPS nl21.cdnaccelerate.com:443; HTTPS nl37.cdnaccelerate.com:443; HTTPS nl18.cdnflare.org:443","no":"HTTPS no1.edgecache.online:16175","pl":"HTTPS pl4.cdnzone.net:443; HTTPS pl3.cdnzone.net:443; HTTPS pl5.cdnzone.net:443","ro":"HTTPS ro3.quickcache.space:14497","rs":"HTTPS rs11.speedstream.info:18413","ru":"HTTPS ru6.edgecache.xyz:5598","se":"HTTPS se16.quickcache.website:7751","sg":"HTTPS sg3.cdnflow.net:23803; HTTPS sg4.cdnflow.net:3178; HTTPS sg5.datafrenzy.org:20571","si":"HTTPS si3.quickcache.click:19300","tr":"HTTPS tr2.speedstream.click:12775","ua":"HTTPS ua3.fastfetch.info:2220","uk":"HTTPS uk26.streamlineddata.pro:7714; HTTPS uk25.contentnode.net:16927; HTTPS uk24.swiftcdn.org:4043","us":"HTTPS us25.datafrenzy.org:4463; HTTPS us26.datafrenzy.org:5905; HTTPS us24.swiftcdn.org:4869","usw":"HTTPS usw11.cdnaccelerate.xyz:23054","za":"HTTPS za8.cacheflow.live:3613"};
const globalReturn = "us";
const siteFilters = [{"format":"domain","country":"fi","value":"browsec.com"}].map(({ format, value, country }) => { if (format === 'regex') value = new RegExp(value); return { format, value, country }; });
const ipRanges = [['0.0.0.0', '255.0.0.0'], ['10.0.0.0', '255.0.0.0'], ['127.0.0.0', '255.0.0.0'], ['169.254.0.0', '255.255.0.0'], ['172.16.0.0', '255.240.0.0'], ['192.0.2.0', '255.255.255.0'], ['192.88.99.0', '255.255.255.0'], ['192.168.0.0', '255.255.0.0'], ['198.18.0.0', '255.254.0.0'], ['224.0.0.0', '240.0.0.0'], ['240.0.0.0', '240.0.0.0']];

function FindProxyForURL(url, host) {
    host = host.toLowerCase();
    const domain = host.split(':')[0];
    const domainIs = function (host, domain) {
        return host === domain || dnsDomainIs(host, '.' + domain);
    };
    const directCondition = (() => {
        if (isPlainHostName(host)) return true;
        if (typeof isInNetEx !== 'undefined') {
            if (isInNetEx(host, 'fc00::/7') || isInNetEx(host, 'fe80::/10')) {
                return true;
            }
        }
        if (!/^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/.test(host)) {
            return false;
        }
        return ipRanges.some(([start, end]) => isInNet(host, start, end));
    })();
    if (directCondition) return 'DIRECT';
    if (["corp","dns","eth","home","ip","intra","intranet","local","onion","tenet","discordapp.io","edit.boxlocalhost.com","localhost.megasyncloopback.mega.nz","localhost.wwbizsrv.alibaba.com","localtest.me","lvh.me","spotilocal.com","vcap.me","www.amazonmusiclocal.com","google-analytics.com","secure.gate2shop.com","cdn.safecharge.com","data-e5.brmtr.org","gist.githubusercontent.com","paddle.com","payment.kassa.ai","yoomoney.ru","data-e5.brmtr.org","servefaststatic.work","staticvaultcdn.org","staticvaultcdn.xyz","cdnflare.org","cdnaccelerate.com","cdnzone.net","cdnflow.net","datafrenzy.org","swiftcdn.org","streamlineddata.pro","contentnode.net","d3qw4xzzzxpncq.cloudfront.net","a703.l461.r761.fastcloudcdn.net","files.staticstream.org"].some(item => domainIs(host, item))) {
        return 'DIRECT';
    }
    const siteFilter = siteFilters.find(filter => {
        switch (filter.format) {
            case 'domain': 
                return domain === filter.value || domain.endsWith('.' + filter.value);
            case 'full domain': 
                return domain === filter.value;
            case 'regex': 
                return filter.value.test(domain);
            default: 
                return false;
        }
    });
    if (!siteFilter) {
        return globalReturn ? countries[globalReturn] : 'DIRECT';
    }
    return siteFilter.country ? countries[siteFilter.country] : 'DIRECT';
}