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

    items.forEach(function (item) {
      item.dataset.searchText = item.textContent.replace(/\s+/g, ' ').trim().toLowerCase();
    });

    function resultText(visibleCount, query) {
      var noun = visibleCount === 1 ? 'result' : 'results';

      if (query) {
        return visibleCount + ' ' + noun + ' for "' + query + '"';
      }

      return '';
    }

    function filterItems() {
      var displayQuery = input.value.replace(/\s+/g, ' ').trim();
      var query = displayQuery.toLowerCase();
      var visibleCount = 0;

      items.forEach(function (item) {
        var isMatch = !query || item.dataset.searchText.indexOf(query) !== -1;

        item.hidden = !isMatch;

        if (isMatch) {
          visibleCount += 1;
        }
      });

      results.textContent = resultText(visibleCount, displayQuery);
      emptyState.hidden = visibleCount !== 0 || !query;
    }

    input.addEventListener('input', filterItems);
    input.addEventListener('search', filterItems);
    filterItems();
  });
});
