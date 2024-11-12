// Entry point for the build script in your package.json
import '@hotwired/turbo-rails';
import './controllers';

///////////////////
// Our Stuff
///////////////////

// NOTE: This must only contain imports, any code added here runs after all the imports happen

// Vendor Stuff
import './custom/add_jquery'; // Add jQuery to the window
import 'jquery-ui';
import 'jquery-query-object';
import '@googlemaps/markerclusterer';

import './custom/maps';
import './custom/sortable';
import './custom/remove_empty_fields';
import './custom/add_university';
import './custom/copy_language';
import './custom/items_and_collections';
import './custom/dynamic_grant_identifiers';
import './custom/item_prev_next';
import './custom/confirm_delete';
