# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If the target framework does not match your intended version, update it and rebuild the solution.

## 2. Restore and Build the Solution

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Confirm that both commands complete with no errors or warnings that could indicate runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review the output for any failing tests and address them before proceeding.

## 4. Validate Runtime Behavior

Run the application locally to confirm it behaves as expected:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Exercise the primary workflows of the application and compare the output against the behavior of the original legacy project.

## 5. Check for Removed or Changed APIs

Review any use of APIs that were available in .NET Framework but have changed or been removed in cross-platform .NET. Key areas to inspect include:

- **`System.Data`** and ADO.NET providers: Confirm that any database drivers (e.g., SQL Server, Oracle, MySQL) have been replaced with their cross-platform NuGet equivalents.
- **`System.Configuration`**: `ConfigurationManager` requires the `System.Configuration.ConfigurationManager` NuGet package on cross-platform .NET.
- **`System.Drawing`**: Requires the `System.Drawing.Common` package and has platform restrictions on non-Windows systems.
- **`AppDomain`, `Remoting`, or `Reflection.Emit`**: Some members behave differently or are not supported.

## 6. Review NuGet Package Compatibility

Open the `.csproj` file and review all `<PackageReference>` entries. For each package, confirm the version listed supports the target framework by checking [NuGet.org](https://www.nuget.org). Replace any packages that only target .NET Framework with their cross-platform equivalents.

## 7. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific issues:

```bash
dotnet run --configuration Release
```

Pay particular attention to:
- File path separators
- Case-sensitive file systems (Linux)
- Platform-specific native dependencies

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
# Framework-dependent publish
dotnet publish --configuration Release --output ./publish

# Self-contained publish for a specific platform (example: Linux x64)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Verify the contents of the `./publish` directory and confirm the application runs correctly from that output folder before deploying to the target environment.