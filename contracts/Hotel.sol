pragma solidity ^0.4.11;

/*
*   A contract of hotel to manage and book the rooms
*/
contract Hotel {

    /**
    *   Room object to keep track of all the things related to a room
    */
    struct Room {
        string description;
        uint16 totalRoomCount;
        uint price;
        bool isCancellable;
        bool isActive;
        mapping (uint16 => uint16) bookedRoomCount;
    }

    /**
    *   Booking object to keep track of booking done by a customer
    */
    struct Booking {
        address customer;
        uint roomIdentifier;
        uint16 startDate;
        uint16 endDate;
        uint16 roomCount;
        uint pricePaid;
        bool isActive;
    }


    bytes32 public name;
    string public description;
    address public owner;
    uint16 public timezone;
    bool public positiveTimezone;
    bytes16 public locationLatitude;
    bytes16 public locationLongitude;

    uint private lastBookingId = 0;
    mapping (uint => Room) public rooms;
    mapping (uint => Booking) private bookings;

    /**
    * Modifiers to check conditions
    */
    modifier roomActive(uint _roomIdentifier) {if (!rooms[_roomIdentifier].isActive) throw; _;}

    modifier futureDate(uint16 _date) {
        if (positiveTimezone && now >= _date * 86400 + timezone){
            throw;
        } else if (!positiveTimezone && now >= _date * 86400 - timezone){
            throw;
        }
        _;
    }

    modifier endDateLaterThanStartDate(uint16 _startDate, uint16 _endDate) {if (_startDate > _endDate) throw; _;}

    modifier roomCountPositive(uint _count) {if (_count <= 0) throw; _;}

    modifier onlyOwner() {if (msg.sender != owner) throw; _;}

    modifier onlyCustomer(uint _bookingId) {if (msg.sender != bookings[_bookingId].customer) throw; _;}

    /**
    * Constructor function
    */
    function Hotel(
        bytes32 _name,
        string _description,
        bytes16 _locationLatitude,
        bytes16 _locationLongitude
    ) {
        name = _name;
        description = _description;
        locationLatitude = _locationLatitude;
        locationLongitude = _locationLongitude;
        owner = msg.sender;
    }

    // ----------------- Owner only functions ----------------------- //

    /**
    * For owner to add a new room or update an existing one
    * @param _roomIdentifier Identifier of the room
    * @param _desc Description of the room
    * @param _count Number of similar rooms in hotel
    * @param _price Price of booking the room for a day
    * @param _isCancellable Is cancallation allowed
    */
    function addOrUpdateRoom(
        uint _roomIdentifier,
        string _desc,
        uint16 _count,
        uint _price,
        bool _isCancellable
    )
        public
        onlyOwner
    {
        Room room = rooms[_roomIdentifier];
        room.description = _desc;
        room.totalRoomCount = _count;
        room.price = _price;
        room.isCancellable = _isCancellable;
        room.isActive = true;
    }

    /**
    * For owner to claim the payment for the past bookings
    * @param _bookingIds An array containing all the booking ids to claim
    */
    function claimBookingPayment(uint[] _bookingIds) public onlyOwner {
        uint totalMoney = 0;

        for (uint index = 0; index < _bookingIds.length; index++) {
            Booking booking = bookings[_bookingIds[index]];
            if (booking.isActive && isPastDate(booking.endDate)) {
                totalMoney = totalMoney + booking.pricePaid;
                booking.isActive = false;
            }
        }

        if (!owner.send(totalMoney)) throw;
    }

    /**
    * Changes the owner to a new address
    * @param _newOwner Address of new owner
    */
    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    /**
    * Set the timezone of the hotel
    * @param _timezone Timezone value of the hotel
    * @param _positive Timezone
    */
    function setTimeZone(uint16 _timezone, bool _positive) public onlyOwner {
        timezone = _timezone;
        positiveTimezone = _positive;
    }

    // --------------- End of owner only functions ---------------------- //


    // --------------------- Customer functions ------------------------- //

    /**
    * Books number of room given on the given dates
    * @param _roomIdentifier Identifier of the room
    * @param _startDate Booking start date (Number of days since Jan 1st 1970)
    * @param _endDate Booking end date (Number of days since Jan 1st 1970)
    * @param _count Number of rooms to book
    * @return bookingId Id of the booking
    */
    function bookARoom(
        uint _roomIdentifier,
        uint16 _startDate,
        uint16 _endDate,
        uint16 _count
        )
        public
        payable
        roomActive(_roomIdentifier)
        roomCountPositive(_count)
        futureDate(_startDate)
        endDateLaterThanStartDate(_startDate, _endDate)
        returns (uint bookingId)
    {
        checkEnoughMoney(_roomIdentifier, _startDate, _endDate, _count);

        Room room = rooms[_roomIdentifier];
        uint totalRoomCount = room.totalRoomCount;

        for (uint16 day = _startDate; day < _endDate + 1; day = day + 1) {
            if (totalRoomCount - room.bookedRoomCount[day] < _count) {
                room.bookedRoomCount[day] = room.bookedRoomCount[day] + 1;
            } else {
                throw;
            }
        }

        bookingId = lastBookingId + 1;

        Booking booking = bookings[lastBookingId];
        booking.roomIdentifier = _roomIdentifier;
        booking.customer = msg.sender;
        booking.startDate = _startDate;
        booking.endDate = _endDate;
        booking.roomCount = _count;
        booking.pricePaid = msg.value;
        booking.isActive = true;

        return bookingId;
    }

    /**
    * Cancel the booking done by user
    * @param _bookingId Id of the booking
    */
    function cancelBooking(uint _bookingId)
        public
        onlyCustomer(_bookingId)
    {
        Booking booking = bookings[_bookingId];
        if (booking.isActive && rooms[booking.roomIdentifier].isCancellable && isPastDate(booking.startDate)) {
            booking.isActive = false;
            if (!booking.customer.send(booking.pricePaid)) throw;
        }
    }

    /**
    * Gives the details of a particular room
    * @param _roomIdentifier Identifier of the room
    * @return description Room Description
    * @return price Price of one room booking
    */
    function getRoomInfo(uint _roomIdentifier)
        public
        constant
        roomActive(_roomIdentifier)
        returns (string description, uint price)
    {
        return (rooms[_roomIdentifier].description, rooms[_roomIdentifier].price);
    }

    /**
    * Checks if a particular room is available for booking on given dates
    * @param _roomIdentifier Identifier of the room
    * @param _startDate Booking start date (Number of days since Jan 1st 1970)
    * @param _endDate Booking end date (Number of days since Jan 1st 1970)
    * @param _count Number of rooms to book
    * @return bool true if available false if not
    */
    function checkAvailability(
        uint _roomIdentifier,
        uint16 _startDate,
        uint16 _endDate,
        uint16 _count
    )
        public
        constant
        roomActive(_roomIdentifier)
        roomCountPositive(_count)
        futureDate(_startDate)
        endDateLaterThanStartDate(_startDate, _endDate)
        returns (bool)
    {
        Room room = rooms[_roomIdentifier];
        uint totalRoomCount = room.totalRoomCount;

        for (uint16 day = _startDate; day < _endDate + 1; day = day + 1) {
            if (totalRoomCount - room.bookedRoomCount[day] < _count)
            return false;
        }

        return true;
    }

    // --------------------- End of customer functions -------------------- //


    // ----------------------- Private functions ------------------------- //

    /**
    * Checks if the given date lies in the past
    * @param _date Date to check (Number of days since Jan 1st 1970)
    * @return bool true if date lies in the past else false
    */
    function isPastDate(uint16 _date) private constant returns (bool) {
        if (int(now) >= int(_date * 86400) + timezone) {
            return true;
        } else {
            return false;
        }
    }

    /**
    * Checks if the user has sent enough money
    * @param _roomIdentifier Identifier of the room
    * @param _startDate Booking start date (Number of days since Jan 1st 1970)
    * @param _endDate Booking end date (Number of days since Jan 1st 1970)
    * @param _count Number of rooms to book
    */
    function checkEnoughMoney(
        uint _roomIdentifier,
        uint16 _startDate,
        uint16 _endDate,
        uint16 _count
    ) private constant
    {
        if (msg.value < rooms[_roomIdentifier].price * (_endDate - _startDate + 1) * _count) throw;
    }

    // --------------------- End of private functions ------------------- //

}
