document.addEventListener('DOMContentLoaded', function () {
  var searchInputs = document.querySelectorAll('[data-conference-search-input]');

  searchInputs.forEach(function (input) {
    var listId = input.getAttribute('aria-controls');
    var list = document.getElementById(listId);

    if (!list) {
      return;
    }

    var items = Array.from(list.querySelectorAll('li'));
    var searchContainer = input.closest('.conference-search');
    var results = searchContainer.querySelector('[data-conference-search-results]');
    var emptyState = searchContainer.querySelector('[data-conference-search-empty]');
    var label = list.dataset.searchLabel || 'conferences';

    items.forEach(function (item) {
      item.dataset.searchText = item.textContent.replace(/\s+/g, ' ').trim().toLowerCase();
    });

    function resultText(visibleCount, query) {
      var noun = visibleCount === 1 ? 'result' : 'results';

      if (query) {
        return visibleCount + ' ' + noun + ' for "' + query + '"';
      }

      return 'Showing all ' + visibleCount + ' ' + label;
    }

    function filterItems() {
      var query = input.value.replace(/\s+/g, ' ').trim().toLowerCase();
      var visibleCount = 0;

      items.forEach(function (item) {
        var isMatch = !query || item.dataset.searchText.indexOf(query) !== -1;

        item.hidden = !isMatch;

        if (isMatch) {
          visibleCount += 1;
        }
      });

      results.textContent = resultText(visibleCount, input.value.trim());
      emptyState.hidden = visibleCount !== 0;
    }

    input.addEventListener('input', filterItems);
    input.addEventListener('search', filterItems);
    filterItems();
  });
});
