import React, { Component } from 'react';
import PropTypes from 'prop-types';
import ScheduleRow from './ScheduleRow';

class ScheduleTable extends Component {
  static propTypes = {
    schedules: PropTypes.array.isRequired,
    deleteSchedule: PropTypes.func.isRequired,
    selectForUpdate: PropTypes.func.isRequired,
    view: PropTypes.func.isRequired,
    deletingSchedule: PropTypes.number.isRequired
  };

  render() {
    return (
      <div className="column">
        <h2 className="subtitle">
          Showing <strong>{this.props.schedules.length}</strong> schedules
        </h2>
        <table className="table is-striped">
          <thead>
            <tr>
              <th>Name</th>
              <th>Database</th>
              <th>Host</th>
              <th>Schedule</th>
              <th>Keep</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {this.props.schedules.map((s, i) => (
            <ScheduleRow
              key={s.id}
              deletingSchedule={this.props.deletingSchedule}
              index={i}
              schedule={s}
              view={this.props.view}
              selectForUpdate={this.props.selectForUpdate}
              deleteSchedule={this.props.deleteSchedule}
            />
            ))}
          </tbody>
        </table>
      </div>
    );
  }
}

export default ScheduleTable;