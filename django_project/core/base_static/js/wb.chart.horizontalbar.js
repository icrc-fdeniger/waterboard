function barChartHorizontal(options) {
    var _INIT_TIME = new Date().getTime();
    var _ID = options.parentId + '_' + _INIT_TIME;
    var _CHART_TYPE = 'HORIZONTAL_BAR_CHART';
    var _NAME = options.name;

    var filterValueField = options.filterValueField || 'group';
    var columns = options.columns;
    var valueField = options.valueField || 'cnt';
    var labelField = options.labelField || 'group';

    var sortKey = options.sortKey || valueField;

    var parentId = options.parentId || 'chart';
    var titleClass = options.titleClass || 'wb-chart-title';
    var barsClass = options.barsClass || 'bar';
    var labelClass = options.labelClass || 'wb-barchart-label';
    var xAxisClass = options.xAxisClass || 'x axis';
    var svgClass = options.svgClass || 'wb-horizontal-bar';
    var toolTipClass = options.toolTipClass || 'wb-horizontal-bar-tooltip';
    var activeBarClass = options.activeBarClass || 'wb-bar-active';

    var showTitle = options.showTitle || true;

    // used for bar label height calculation
    var fontSize = options.fontSize || 12;

    var barsCnt = options.barsCnt || 7;
    var _barHeight = 20;

    var barClickHandler = options.barClickHandler;
    var tooltipRenderer = options.tooltipRenderer || function () {
        return 'Default Tooltip'
    };

    var title = options.title;
    var _activeBars = [];

    var _margin = options.margin || {
        top: 15,
        right: 15,
        bottom: 20,
        left: 15
    };
    var opacityHover = 1;
    var otherOpacityOnHover = .6;

    var _svgWidth;
    var _svgHeight = options.height || 200;
    var _width;
    var _height;


    var _data;


    var parent = document.getElementById(parentId);

    // TODO - append to chart div maybe?
    var tooltip = d3.select('body').append("div")
        .attr("class", toolTipClass)
        .attr("id", 'wb_tooltip_' + _ID);

    // helper - returns value of data object
    function _xValue(d) {
        return WB.utils.getNestedProperty(d, valueField) || 0;
    }

    // helper - returns label of data object
    function _yValue(d) {
        return WB.utils.getNestedProperty(d, labelField);
    }

    // helper - generates id for data object based on label
    function _generateBarId(d) {

        var label = (_yValue(d)).replace(/[^a-z0-9]+/gi, '');
        return [_ID, label].join('_');
    }

    // x axis scale
    var _xScale = d3.scaleLinear();

    // y axis scale
    var _yScale = d3.scaleBand();

    // axis scale value helper
    function _xScaleValue(d) {
        return _xScale((_xValue(d) || 0));
    }

    // axis
    var _xAxis = d3.axisBottom(_xScale);

    var _svg;
    // Axis group and x axis, y axis not used
    var _axisGroup;
    var _xAxisGroup;

    // Chart Group - represented data
    var _chartGroup;

    // Chart title group
    var _titleGroup;

    var updateChart, _handleMouseMove;


    /**
     * Add svg to dom
     * Add all groups to svg and apply base transformation using margin
     * @private
     */
    function _renderSvgElements(parentId) {
        // main svg
        _svg = d3.select('#' + parentId).append('svg')
            .classed(svgClass, true);

        _axisGroup = _svg.append("g")
            .classed('axis-group', true)
            .attr("transform", "translate(" + [_margin.left, _svgHeight - _margin.top] + ")");

        _xAxisGroup = _axisGroup.append("g")
            .classed(xAxisClass, true);

        _chartGroup = _svg.append("g")
            .classed('chart-group', true)
             .on("mouseout", function () {
                 d3.select(this).selectAll('.' + barsClass + '_group')
                .style("opacity", opacityHover)
             })

            .attr("transform", "translate(" + [_margin.left, _margin.top + _margin.bottom] + ")");

        _titleGroup = _svg.append("g")
            .classed('title-group', true)
            .attr("transform", "translate(" + [0, _margin.top + 2] + ")");
    }

    function _chart(parentId) {
        _renderSvgElements(parentId);


        function _setScales() {
            // use predefined y labels or take them from data
            var cols = columns ? columns : _data.map(_yValue);

            _yScale
                .domain(cols)
                .range([_height, 0])
                .padding(0.1);

            _xScale
                .domain([0, d3.max(_data, _xValue)])
                .range([0, _width]);
        }

        // Set size and domains
        function _resize() {
            _svg
                .attr("width", _svgWidth)
                .attr("height", _svgHeight);

            _axisGroup
                .attr("width", _svgWidth)
                .attr("height", _svgHeight);

            _chartGroup
                .attr("width", _width)
                .attr("height", _height);

            _xAxisGroup
                .call(_xAxis.ticks(5).tickSizeInner([-_svgHeight + _margin.bottom + _margin.top]));

        }

        function addTitle() {
            _titleGroup.append("text")
                .attr("class", titleClass)
                .attr("transform", "rotate(-90)")
                .attr("y", 10)
                .attr("text-anchor", "end")
                .text(title);

        }

        // returns default class with appended active class if id in _activeBars
        function _getBarClass(d) {
            if (_activeBars.indexOf(_yValue(d)) > -1) {
                return barsClass + ' wb-bar-active';
            }
            return barsClass;
        }

        // set size based on parent dom, used with window resize
        function _calcSize() {
            var bounds = parent.getBoundingClientRect();

            _chart.width(bounds.width);
            _chart.height(200);
            // _chart.height(bounds.height);
        }

        // if new data is not set, only redraw
        updateChart = function () {

            _calcSize();
            _setScales();
            _resize();

            // select all bar groups, 1 group per bar
            var barGroups = _chartGroup.selectAll('.' + barsClass + '_group')
                .data(_data);

            // ENTER - add groups
            var newBarGroups = barGroups.enter().append("g")
                .attr("class", barsClass + '_group')
                .attr("id", _generateBarId)
                .on("mousemove", _handleMouseMove)
                .on("mouseout", _handleMouseOut)
                .on("mouseover", _handleMouseOver)
                .on("click", _handleClick);

            // add bar to group
            newBarGroups
                .append("rect")
                .attr("class", _getBarClass);

            // add text to group
            newBarGroups
                .append("text")
                .attr("class", labelClass);

            // UPDATE - bar
            barGroups.merge(newBarGroups).select('.' + barsClass)
                .attr("x", 0)
                .attr("y", function (d, i) {
                    return i * (_barHeight + 2) - (_barHeight + fontSize / 2) / 2;
                })
                .attr("height", _barHeight)
                .attr("width", _xScaleValue);

            // UPDATE - text
            barGroups.merge(newBarGroups).select('.' + labelClass)
                .attr("y", function (d, i) {
                    return i * (_barHeight + 2);
                })
                .attr("x", 0)
                .text(_yValue);

            // EXIT
            barGroups.exit().remove();
        };

        /**
         * Toggle clicked bar class, add / remove clicked bar from _activeBars
         * @param selection
         * @param isActive
         * @param key
         * @private
         */
        function _toggleActiveBar(selection, isActive, key) {
            if (isActive === -1) {
                selection.classed(activeBarClass, true);
                _activeBars[_activeBars.length] = key;
            } else {
                selection.classed(activeBarClass, false);
                _activeBars.splice(isActive, 1);
            }
        }

        function _handleAdditionalClick(d, isActive) {
            if (barClickHandler && barClickHandler instanceof Function) {
                barClickHandler({
                    data: d,
                    name: _NAME,
                    filterValue: d[filterValueField],
                    chartType: _CHART_TYPE,
                    chartId: _ID,
                    isActive: isActive > -1
                });
            }
        }

        /**
         * Main bar click handler
         * toggles _activeBars and calls user defined callback
         * @param d - bar data
         * @private
         */
        function _handleClick(d) {

            var barLabel = _yValue(d);
            var isActive = _activeBars.indexOf(barLabel);

            _toggleActiveBar(d3.select(this), isActive, barLabel);

            // handle click event defined in configuration
            _handleAdditionalClick(d, isActive);
        }

        _handleMouseMove = function(d) {
            // NOTE: when the mouse cursor goes over the tooltip, tooltip flickering will appear

            var tooltipContent = tooltipRenderer(d);
            tooltip
                .style("display", 'inline-block')
                .html(tooltipContent);

            var tooltipSize = tooltip.node().getBoundingClientRect();
            tooltip
                .style("display", 'inline-block')
                .style("left", d3.event.pageX - 50 + "px")
                .style("top", d3.event.pageY - (tooltipSize.height + 10) + "px")
                .html(tooltipContent);
        }

        function _handleMouseOut(d) {
            tooltip.style("display", "none");
        }
        function _handleMouseOver(d) {

            // change opacity of all paths
            _chartGroup
                .selectAll('.' + barsClass + '_group')
                .style("opacity", otherOpacityOnHover);

            // change opacity of hovered
            d3.select(this).style("opacity", opacityHover);
            console.log('a', this, d3.select(this));
        }

        if (_data) {
            updateChart();
        }

        if (showTitle === true) {
            addTitle();
        }

    }

    _chart.noData = function (show) {
        if (show === true) {
            _chartGroup.append("text").attr("class", 'no-data')
                .text("No Data")
                .style("font-size", "20px");
        } else {
            _chartGroup.select(".no-data").remove();
        }

        return _chart;

    };


    _chart.title = function (value) {
        if (!arguments.length) {
            return title;
        }
        title = value;

        return _chart;
    };

    _chart.showTitle = function (value) {
        if (!arguments.length) {
            return showTitle;
        }
        showTitle = value === true;

        return _chart;
    };

    _chart.width = function (value) {
        if (!arguments.length) {
            return _svgWidth;
        }
        _svgWidth = value;
        _width = _svgWidth - _margin.left - _margin.right;

        return _chart;
    };

    _chart.height = function (value) {
        if (!arguments.length) {
            return _svgHeight;
        }
        _svgHeight = value;
        _height = _svgHeight - _margin.top - _margin.bottom;

        _barHeight = (_height - (barsCnt * 2)) / barsCnt;

        return _chart;
    };

    _chart.activeBars = function (value) {
        if (!arguments.length) {
            return _activeBars;
        }
        _activeBars = value;

        return _chart;
    };

    _chart.data = function (value) {
        if (!arguments.length) {
            return _data;
        }
        _data = _sortData(value, true, sortKey);

        if (typeof updateChart === 'function') {
            updateChart();
        }
        return _chart;
    };

    _chart.resize = function () {
        updateChart();

        return _chart;
    };

    _chart.resetActive = function () {
        _chartGroup.selectAll('.' + activeBarClass)
            .classed(activeBarClass, false);

        _activeBars = [];

        return _chart;
    };

    return _chart;
}
