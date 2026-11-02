"""Membaca file O*NET yang dibutuhkan sekali, menyimpan ke pickle."""
import openpyxl, pickle, collections, os, sys
D = os.path.expanduser('~/Downloads/_onet_tmp/db_30_3_excel/')
OUT = os.path.join(os.environ.get('TMPDIR', '/tmp'), 'navika_onet_0047.pkl')

def rows(f):
    ws = openpyxl.load_workbook(D + f, read_only=True).active
    it = ws.iter_rows(values_only=True); h = next(it)
    for r in it: yield dict(zip(h, r))

if not os.path.exists(OUT):
    im = collections.defaultdict(dict)          # soc -> task -> importance
    for r in rows('Task Ratings.xlsx'):
        if r['Scale ID'] == 'IM': im[r['O*NET-SOC Code']][r['Task ID']] = float(r['Data Value'])
    t2d = collections.defaultdict(list)         # soc -> [(task, dwa)]
    dwa_name = {}
    for r in rows('Tasks to DWAs.xlsx'):
        t2d[r['O*NET-SOC Code']].append((r['Task ID'], r['DWA Element ID'])); dwa_name[r['DWA Element ID']] = r['DWA Element Name']
    dwa_iwa, iwa_name, iwa_gwa = {}, {}, {}
    for r in rows('GWAs to IWAs to DWAs.xlsx'):
        dwa_iwa[r['DWA Element ID']] = r['IWA Element ID']; iwa_name[r['IWA Element ID']] = r['IWA Element Name']; iwa_gwa[r['IWA Element ID']] = r['GWA Element ID']
    sw = collections.defaultdict(list)          # soc -> [(example, element_id, hot)]
    for r in rows('Software Skills.xlsx'):
        sw[r['O*NET-SOC Code']].append((r['Workplace Example'], r['Element ID'], r['Hot Technology'] == 'Y'))
    pickle.dump(dict(im=dict(im), t2d=dict(t2d), dwa_name=dwa_name, dwa_iwa=dwa_iwa, iwa_name=iwa_name, iwa_gwa=iwa_gwa, sw=dict(sw)), open(OUT, 'wb'))
    print('cache dibuat', file=sys.stderr)
O = pickle.load(open(OUT, 'rb'))

def top_dwa(soc, n=8):
    im = O['im'].get(soc, {}); per = collections.defaultdict(list)
    for task, dwa in O['t2d'].get(soc, []):
        if task in im: per[dwa].append(im[task])
    sk = [(round(max(v), 2), d) for d, v in per.items()]
    if not sk:   # SOC tanpa rating task: importance 0, urut kode (sama dengan 0026)
        sk = [(0.0, d) for d in sorted({d for _, d in O['t2d'].get(soc, [])})]
    sk.sort(key=lambda x: (-x[0], x[1]))
    return sk[:n]
