// pre-defined translation tables
var TRANSLATION_TABLE_ALPHA = {' ':0, A: 1, B: 2, C: 3, D: 4, E: 5, F: 6, G: 7, H: 8, I: 9, J: 10, K: 11, L: 12, M: 13, N: 14, O: 15, P: 16, Q: 17, R: 18, S: 19, T: 20, U: 21, V: 22, W: 23, X: 24, Y: 25, Z: 26 };  //{' ':0, a: 1, b: 2, c: 3, d: 4, e: 5, f: 6, g: 7, h: 8, i: 9, j: 10, k: 11, l: 12, m: 13, n: 14, o: 15, p: 16, q: 17, r: 18, s: 19, t: 20, u: 21, v: 22, w: 23, x: 24, y: 25, z: 26 };
var TRANSLATION_TABLE_NUMBER = {'0':0, '1':1, '2':2, '3':3, '4':4, '5':5, '6':6, '7':7, '8':8, '9':9 };
var TRANSLATION_TABLE_MONTH = {'1':0, '2':1, '3':2, '4':3, '5':4, '6':5, '7':6, '8':7, '9':8, '10':9, '11': 10, '12':11 };


var DEFAULT_SCANTRON_LAYOUT = 'UVic';

// A pre-defined layouts for scantrons.
// Any additional scantron layout should be added here.
// All units are in pts (1pt = 1/72 inches).
// Any entries not starting with '_' are assumed to be scantron fields
var SCANTRON_LAYOUTS = {
    'UVic': {
    	_printerOffsets: {
		'4250': [-3.5, 2]
	},
        //_defaultOrder: ['Student ID', 'Name', 'Course and Section'],
        //_defaultOrder: ['Course and Section', 'Name', 'Student ID'],
        _defaultOrder: ['nouse', 'nouse', 'nouse', 'Student ID', 'Last Name', 'First Name', 'nouse', 'nouse', 'nouse', 'Course Number', 'Section', 'Last, First Name', 'Middle Name'],
        'Name': {
            textExtents: [30,213,270,237],
            bubbleExtents: [30,237,270,560], 
            rows: 27,
            cols: 20, 
            layout: 'vertical',
            translationTable: TRANSLATION_TABLE_ALPHA
        },
        'Student ID': {
            textExtents: [30,56,114,80],
            bubbleExtents: [30,80,114,202], 
            rows: 10,
            cols: 7, 
            layout: 'vertical',
            translationTable: TRANSLATION_TABLE_NUMBER
        },
        'Course and Section': {
            textExtents: [114,56,175,80],
            bubbleExtents: [114,80,175,202], 
            rows: 10,
            cols: 5, 
            layout: 'vertical',
            translationTable: TRANSLATION_TABLE_NUMBER
        },
        'Special': {
            textExtents: [60+115,60+56,60+175,60+80],
            bubbleExtents: [60+115,60+80,60+175,60+202], 
            rows: 10,
            cols: 5, 
            layout: 'vertical',
            translationTable: TRANSLATION_TABLE_NUMBER
        },
        'Month': {
            textExtents: null,
            bubbleExtents: [234, 56, 234+13, 56+145], 
            rows: 12,
            cols: 1, 
            layout: 'vertical',
            translationTable: TRANSLATION_TABLE_MONTH
        },
        'Day': {
            textExtents: [247, 56, 247+23, 55+25],
            bubbleExtents: [247, 79, 247+23, 79+122], 
            rows: 10,
            cols: 2, 
            layout: 'vertical',
            translationTable: TRANSLATION_TABLE_NUMBER
        },
        'Year': {
            textExtents: [271, 56, 270+23, 55+25],
            bubbleExtents: [271, 79, 270+23, 79+122], 
            rows: 10,
            cols: 2, 
            layout: 'vertical',
            translationTable: TRANSLATION_TABLE_NUMBER
        },
    }
}
