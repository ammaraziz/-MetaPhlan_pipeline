import pickle
import bz2

db = pickle.load(bz2.BZ2File('mpa_v20_m200.pkl', 'r'))

for key in db['markers']:
    if 'Burkholderia_mallei' in db['markers'][key]['clade']:
        print("old....................")
        print(db['markers'][key])
        print(db['markers'][key]['clade'])
        print(db['markers'][key]['taxon'])
        #change taxon
        tmp_taxon = db['markers'][key]['taxon'].split("|")
        tmp_taxon[-1] = "s__Burkholderia_pseudomallei"
        db['markers'][key]['taxon'] = '|'.join(tmp_taxon)
        #change clade
        db['markers'][key]['clade'] = 's__Burkholderia_pseudomallei'
        print("new.....................................")
        print(db['markers'][key]['clade'])
        print(db['markers'][key]['taxon'] )

ofile = bz2.BZ2File('mpa_v20_m200_MOD.pkl', 'w')
pickle.dump(db, ofile, protocol=pickle.HIGHEST_PROTOCOL)
ofile.close()