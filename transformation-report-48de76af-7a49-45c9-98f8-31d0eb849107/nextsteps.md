# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version mismatches. If any packages previously referenced were Windows-only (e.g., packages targeting `net4x`), verify that cross-platform equivalents are in place.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review the build output for any warnings that may indicate compatibility concerns, even if they are not hard errors.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Pay attention to any tests that were previously passing in the legacy project but now fail, as these may indicate behavioral differences between .NET Framework and modern .NET.

## 5. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been replaced with cross-platform alternatives that behave differently at runtime. Review the code for usage of the following and test them explicitly on each target platform:

- File system path handling (`System.IO.Path`)
- Registry access (`Microsoft.Win32.Registry`) — not available on Linux/macOS
- Windows-specific interop (`DllImport` with system DLLs)
- `System.Drawing` — requires additional packages on non-Windows platforms

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any runtime-only issues:

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application for your target runtime. For a self-contained deployment targeting Linux x64 as an example:

```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

For a framework-dependent deployment:

```bash
dotnet publish -c Release -o ./publish
```

Review the contents of the `./publish` directory to confirm all required files are present before distributing or deploying.