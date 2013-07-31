YUI().use('node','event', function(){
    createStoryJS({
        type:       'timeline',
        width:      '800',
        height:     '600',
        source:     'scripts/example_json.json',
        embed_id:   'PBM-homepage-timeline'
    });
});