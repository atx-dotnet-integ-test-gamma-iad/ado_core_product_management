# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it does not match your intended target, update it and rebuild the solution.

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or unlisted packages that may need to be updated.

## 3. Build the Solution

Perform a clean build to confirm there are no hidden build issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review the build output for any warnings that, while non-blocking, may indicate compatibility concerns.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 5. Check for Runtime Compatibility Issues

Even with a clean build, certain APIs behave differently on cross-platform .NET. Pay attention to the following areas:

- **Database connectivity**: If `AdoCore` implies ADO.NET usage, verify that the database drivers (e.g., `System.Data.SqlClient` vs `Microsoft.Data.SqlClient`) are compatible and correctly referenced.
- **File path handling**: Ensure no hardcoded Windows-style paths (`\`) exist; use `Path.Combine` instead.
- **Configuration**: Verify that any `App.config` or `Web.config` files have been migrated to `appsettings.json` or equivalent .NET configuration patterns.
- **Reflection and serialization**: Test any code that relies on reflection, `BinaryFormatter`, or legacy serialization APIs, as several of these are removed or restricted in modern .NET.

## 6. Run the Application Manually

Execute the application directly to observe runtime behavior:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Test the primary workflows of the application and confirm outputs match expected behavior from the legacy version.

## 7. Test on Target Platforms

Since the goal is cross-platform support, run the application on each intended operating system (Windows, Linux, macOS) to identify any platform-specific issues that do not surface during build.

## 8. Review NuGet Package Compatibility

Run the following command to check for outdated packages:

```bash
dotnet list package --outdated
```

Update packages where appropriate, particularly any that were carried over from the legacy project and may have newer cross-platform-compatible versions available.

## 9. Publish the Application

Once validation is complete, publish the application for your target runtime:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained true
```

Replace `<runtime-identifier>` with the appropriate value, for example:
- `win-x64` for Windows
- `linux-x64` for Linux
- `osx-x64` for macOS

The published output will be located in the `bin/Release/<tfm>/<rid>/publish/` directory.