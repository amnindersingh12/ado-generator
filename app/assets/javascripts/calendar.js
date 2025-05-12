document.addEventListener("DOMContentLoaded", function () {
    const calendarDays = document.querySelectorAll(".calendar-day");

    calendarDays.forEach(function (day) {
        day.addEventListener("mouseenter", function (e) {
            const date = e.target.dataset.date;
            const tooltip = document.getElementById("tooltip");

            // Fetch the data dynamically for the hovered day
            fetch(`/calendar/day_data?year=${new Date(date).getFullYear()}&month=${new Date(date).getMonth() + 1}&day=${new Date(date).getDate()}`)
                .then(response => response.text())
                .then(data => {
                    tooltip.innerHTML = data;
                    tooltip.style.display = "block";
                    tooltip.style.left = `${e.pageX + 10}px`;
                    tooltip.style.top = `${e.pageY + 10}px`;
                })
                .catch(error => console.error("Error fetching day data:", error));
        });

        day.addEventListener("mouseleave", function () {
            document.getElementById("tooltip").style.display = "none";
        });
    });
});
